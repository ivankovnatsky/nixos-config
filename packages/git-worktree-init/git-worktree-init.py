#!/usr/bin/env python3
"""
Git worktree initialization tool.

Creates or navigates to a git worktree for the specified branch.
Worktrees are created at <git-dir>/__worktrees/<branch-name>.
"""

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path


DEFAULT_CHAR_LIMIT = 35


def run_git(*args: str, capture: bool = True, check: bool = True) -> str:
    """Run a git command and return stdout."""
    try:
        result = subprocess.run(
            ["git", *args],
            capture_output=capture,
            text=True,
            check=check,
        )
        return result.stdout.strip() if capture else ""
    except subprocess.CalledProcessError:
        return ""


def get_git_root() -> Path | None:
    """Get the root of the git repository."""
    root = run_git("rev-parse", "--show-toplevel")
    return Path(root) if root else None


def get_git_common_dir() -> Path | None:
    """Get the common git directory (handles worktrees correctly)."""
    common_dir = run_git("rev-parse", "--git-common-dir")
    if not common_dir:
        return None
    path = Path(common_dir).resolve()
    if path.name == ".git":
        return path
    return path


def get_real_git_root() -> Path | None:
    """Get the real git root, even when inside a worktree."""
    common_dir = get_git_common_dir()
    if not common_dir:
        return None
    if common_dir.name == ".git":
        return common_dir.parent
    return common_dir.parent


def get_default_branch() -> str | None:
    """Detect the default branch from origin/HEAD."""
    ref = run_git("symbolic-ref", "refs/remotes/origin/HEAD")
    if ref:
        return ref.replace("refs/remotes/origin/", "")
    return None


def trim_branch_name(name: str, char_limit: int) -> str:
    """Trim branch name to char_limit, breaking at word boundaries."""
    if len(name) <= char_limit:
        return name

    trimmed = name[:char_limit]
    last_separator = max(trimmed.rfind("-"), trimmed.rfind("_"))
    if last_separator > 0:
        trimmed = trimmed[:last_separator]

    return trimmed.rstrip("-_")


def process_branch_name(
    branch: str,
    char_limit: int,
    no_trim: bool,
    sha_suffix: bool,
    current_sha: str | None,
) -> str:
    """Process branch name with optional trimming and SHA suffix."""
    if no_trim:
        result = branch
    else:
        match = re.match(r"^([^/]+/)", branch)
        prefix = match.group(1) if match else ""
        name_part = branch[len(prefix) :]

        trimmed_name = trim_branch_name(name_part, char_limit)
        result = f"{prefix}{trimmed_name}"

    if sha_suffix and current_sha:
        short_sha = current_sha[:7]
        if not result.endswith(f"-{short_sha}"):
            result = f"{result}-{short_sha}"

    return result


def branch_exists(branch: str) -> bool:
    """Check if a branch exists locally."""
    try:
        subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", f"refs/heads/{branch}"],
            check=True,
            capture_output=True,
        )
        return True
    except subprocess.CalledProcessError:
        return False


def create_worktree(worktree_dir: Path, branch: str, base_branch: str | None) -> bool:
    """Create a git worktree."""
    worktree_dir.parent.mkdir(parents=True, exist_ok=True)

    if branch_exists(branch):
        result = run_git("worktree", "add", str(worktree_dir), branch, check=False)
    else:
        if base_branch:
            result = run_git("worktree", "add", "-b", branch, str(worktree_dir), base_branch, check=False)
        else:
            result = run_git("worktree", "add", "-b", branch, str(worktree_dir), check=False)

    return worktree_dir.exists()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Create or navigate to a git worktree for the specified branch.",
        epilog="""
The worktree is created at <git-dir>/__worktrees/<branch-name>.
If the branch doesn't exist, it will be created.

Example:
  %(prog)s feature/DOPS-12345-some-description
  %(prog)s --no-pull feature/quick-fix
  %(prog)s --sha-suffix feature/TICKET-123
""",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "branch",
        help="The branch name for the worktree (e.g., feature/TICKET-123)",
    )
    parser.add_argument(
        "--no-trim",
        action="store_true",
        help="Disable branch name trimming (default: trim enabled)",
    )
    parser.add_argument(
        "--char-limit",
        type=int,
        default=DEFAULT_CHAR_LIMIT,
        help=f"Character limit for branch name part (default: {DEFAULT_CHAR_LIMIT})",
    )
    parser.add_argument(
        "--sha-suffix",
        action="store_true",
        help="Append 7-char SHA to branch name for uniqueness (default: disabled)",
    )
    parser.add_argument(
        "--no-pull",
        action="store_true",
        help="Skip checkout and pull of default branch (default: pull enabled)",
    )

    args = parser.parse_args()

    git_root = get_git_root()
    if not git_root:
        print("Error: Not in a git repository", file=sys.stderr)
        return 1

    real_git_root = get_real_git_root()
    if not real_git_root:
        print("Error: Could not determine git root", file=sys.stderr)
        return 1

    git_dir = get_git_common_dir()
    if not git_dir:
        print("Error: Could not determine git directory", file=sys.stderr)
        return 1

    os.chdir(real_git_root)

    default_branch = get_default_branch()
    current_sha = None

    if not args.no_pull:
        if default_branch:
            run_git("checkout", default_branch, check=False)
            run_git("pull", "origin", default_branch, check=False)
            current_sha = run_git("rev-parse", "HEAD")
        else:
            current_sha = run_git("rev-parse", "HEAD")
    else:
        current_sha = run_git("rev-parse", "HEAD")

    branch_name = process_branch_name(
        args.branch,
        args.char_limit,
        args.no_trim,
        args.sha_suffix,
        current_sha,
    )

    worktree_dir = git_dir / "__worktrees" / branch_name

    if worktree_dir.exists():
        print(worktree_dir, end="")
        return 0

    if not create_worktree(worktree_dir, branch_name, default_branch):
        print(f"Error: Failed to create worktree at {worktree_dir}", file=sys.stderr)
        return 1

    print(worktree_dir, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
