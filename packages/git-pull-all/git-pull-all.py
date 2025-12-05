#!/usr/bin/env python3
"""Recursively pull all git repositories under a directory."""

import argparse
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path


@dataclass
class PullResult:
    """Result of a git pull operation."""

    path: Path
    success: bool
    message: str
    skipped: bool = False


def find_git_repos(base_dir: Path) -> list[Path]:
    """Recursively find all git repositories under base_dir."""
    repos = []
    for root, dirs, _ in os.walk(base_dir):
        if ".git" in dirs:
            repos.append(Path(root))
            # Don't descend into git repo subdirectories
            dirs.clear()
        # Skip hidden directories (except we already handled .git)
        dirs[:] = [d for d in dirs if not d.startswith(".")]
    return repos


def get_default_branch_gh(repo_path: Path) -> str | None:
    """Get the default branch using gh CLI."""
    try:
        result = subprocess.run(
            ["gh", "repo", "view", "--json", "defaultBranchRef", "-q", ".defaultBranchRef.name"],
            cwd=repo_path,
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, subprocess.SubprocessError):
        pass
    return None


def get_default_branch_git(repo_path: Path) -> str | None:
    """Get the default branch using git (fallback)."""
    # Try symbolic ref first
    try:
        result = subprocess.run(
            ["git", "symbolic-ref", "refs/remotes/origin/HEAD"],
            cwd=repo_path,
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode == 0:
            return result.stdout.strip().replace("refs/remotes/origin/", "")
    except (subprocess.TimeoutExpired, subprocess.SubprocessError):
        pass

    # Try common branch names
    for branch in ["main", "master", "develop"]:
        try:
            result = subprocess.run(
                ["git", "show-ref", "--verify", f"refs/remotes/origin/{branch}"],
                cwd=repo_path,
                capture_output=True,
                text=True,
                timeout=10,
            )
            if result.returncode == 0:
                return branch
        except (subprocess.TimeoutExpired, subprocess.SubprocessError):
            pass

    return None


def get_default_branch(repo_path: Path) -> str | None:
    """Get the default branch, trying gh CLI first, then git."""
    branch = get_default_branch_gh(repo_path)
    if branch:
        return branch
    return get_default_branch_git(repo_path)


def has_no_commits(repo_path: Path) -> bool:
    """Check if repository has no commits yet."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=repo_path,
            capture_output=True,
            timeout=10,
        )
        return result.returncode != 0
    except (subprocess.TimeoutExpired, subprocess.SubprocessError):
        return False


def has_uncommitted_changes(repo_path: Path) -> bool:
    """Check if repository has uncommitted changes."""
    try:
        # Refresh the index first to avoid false positives from stale stat info
        subprocess.run(
            ["git", "update-index", "--refresh"],
            cwd=repo_path,
            capture_output=True,
            timeout=30,
        )
        result = subprocess.run(
            ["git", "diff-index", "--quiet", "HEAD", "--"],
            cwd=repo_path,
            capture_output=True,
            timeout=30,
        )
        return result.returncode != 0
    except (subprocess.TimeoutExpired, subprocess.SubprocessError):
        return True  # Assume dirty if we can't check


def pull_repo(repo_path: Path) -> PullResult:
    """Pull a single git repository."""
    # Check for empty repository (no commits)
    if has_no_commits(repo_path):
        return PullResult(
            path=repo_path,
            success=False,
            message="empty repository (no commits)",
            skipped=True,
        )

    # Check for uncommitted changes
    if has_uncommitted_changes(repo_path):
        return PullResult(
            path=repo_path,
            success=False,
            message="uncommitted changes",
            skipped=True,
        )

    # Get default branch
    default_branch = get_default_branch(repo_path)
    if not default_branch:
        return PullResult(
            path=repo_path,
            success=False,
            message="could not determine default branch",
        )

    # Get current branch
    try:
        result = subprocess.run(
            ["git", "branch", "--show-current"],
            cwd=repo_path,
            capture_output=True,
            text=True,
            timeout=10,
        )
        current_branch = result.stdout.strip()
    except (subprocess.TimeoutExpired, subprocess.SubprocessError):
        return PullResult(
            path=repo_path,
            success=False,
            message="could not get current branch",
        )

    # Checkout default branch if needed
    if current_branch and current_branch != default_branch:
        try:
            subprocess.run(
                ["git", "checkout", default_branch],
                cwd=repo_path,
                capture_output=True,
                timeout=30,
            )
        except (subprocess.TimeoutExpired, subprocess.SubprocessError):
            return PullResult(
                path=repo_path,
                success=False,
                message=f"failed to checkout {default_branch}",
            )

    # Pull
    try:
        result = subprocess.run(
            ["git", "pull", "origin", default_branch],
            cwd=repo_path,
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode == 0:
            return PullResult(
                path=repo_path,
                success=True,
                message=f"pulled {default_branch}",
            )
        else:
            return PullResult(
                path=repo_path,
                success=False,
                message=f"pull failed: {result.stderr.strip()}",
            )
    except subprocess.TimeoutExpired:
        return PullResult(
            path=repo_path,
            success=False,
            message="pull timed out",
        )
    except subprocess.SubprocessError as e:
        return PullResult(
            path=repo_path,
            success=False,
            message=f"pull error: {e}",
        )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Recursively pull all git repositories under a directory"
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=os.path.expanduser("~/Sources"),
        help="Base directory to search for git repos (default: ~/Sources)",
    )
    parser.add_argument(
        "-j",
        "--jobs",
        type=int,
        default=4,
        help="Number of parallel jobs (default: 4)",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Show all results, not just errors",
    )
    args = parser.parse_args()

    base_dir = Path(args.directory).expanduser().resolve()
    if not base_dir.is_dir():
        print(f"Error: {base_dir} is not a directory", file=sys.stderr)
        return 1

    print(f"Searching for git repositories in {base_dir}...")
    repos = find_git_repos(base_dir)
    print(f"Found {len(repos)} repositories")

    if not repos:
        return 0

    success_count = 0
    error_count = 0
    skipped_count = 0

    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {executor.submit(pull_repo, repo): repo for repo in repos}

        for future in as_completed(futures):
            result = future.result()
            rel_path = result.path.relative_to(base_dir)

            if result.skipped:
                skipped_count += 1
                print(f"SKIPPED {rel_path}: {result.message}")
            elif result.success:
                success_count += 1
                if args.verbose:
                    print(f"OK      {rel_path}: {result.message}")
            else:
                error_count += 1
                print(f"ERROR   {rel_path}: {result.message}")

    print()
    print("=" * 40)
    print("SUMMARY")
    print("=" * 40)
    print(f"Success: {success_count}")
    print(f"Errors:  {error_count}")
    print(f"Skipped: {skipped_count}")
    print("=" * 40)

    return 0 if error_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
