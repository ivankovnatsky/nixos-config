#!/usr/bin/env python3
"""
Purge git worktrees whose branches are fully merged into their main branch.
Scans all git repositories under ghq root.
"""

import os
import subprocess
import sys
from pathlib import Path

import click


def run(
    cmd: list[str], capture: bool = True, check: bool = False
) -> subprocess.CompletedProcess | None:
    """Run a command and return the CompletedProcess, or None on failure when check=True."""
    try:
        return subprocess.run(cmd, capture_output=capture, text=True, check=check)
    except subprocess.CalledProcessError:
        return None


def run_stdout(cmd: list[str]) -> str:
    """Run a command and return stdout, or empty string on failure."""
    result = run(cmd)
    return result.stdout.strip() if result else ""


def get_ghq_root() -> Path:
    """Get the ghq root directory."""
    root = run_stdout(["ghq", "root"])
    if not root:
        click.echo("Error: could not determine ghq root", err=True)
        sys.exit(1)
    return Path(root)


def find_repos(ghq_root: Path) -> list[Path]:
    """Find all git repositories (main repos have .git as a directory)."""
    repos = []
    for root, dirs, _files in os.walk(ghq_root):
        if ".git" in dirs:
            repos.append(Path(root))
            dirs.clear()
    return repos


def get_main_branch(repo: Path) -> str | None:
    """Detect the main branch for a repository."""
    ref = run_stdout(
        ["git", "-C", str(repo), "symbolic-ref", "refs/remotes/origin/HEAD"]
    )
    if ref:
        return ref.replace("refs/remotes/origin/", "")
    # Check common branch names as fallback
    for candidate in ["main", "master"]:
        result = run(
            ["git", "-C", str(repo), "show-ref", "--verify", f"refs/heads/{candidate}"],
            check=True,
        )
        if result:
            return candidate
    return None


def is_ancestor(repo: Path, branch: str, main_branch: str) -> bool:
    """Check if branch is fully merged into main_branch."""
    try:
        subprocess.run(
            [
                "git",
                "-C",
                str(repo),
                "merge-base",
                "--is-ancestor",
                branch,
                main_branch,
            ],
            capture_output=True,
            check=True,
        )
        return True
    except subprocess.CalledProcessError:
        return False


def parse_worktrees(repo: Path) -> list[dict[str, str]]:
    """Parse git worktree list --porcelain output into structured data."""
    output = run_stdout(["git", "-C", str(repo), "worktree", "list", "--porcelain"])
    worktrees = []
    current: dict[str, str] = {}

    for line in output.splitlines():
        if line.startswith("worktree "):
            current = {"path": line[len("worktree ") :]}
        elif line.startswith("HEAD "):
            current["head"] = line[len("HEAD ") :]
        elif line.startswith("branch "):
            current["branch"] = line[len("branch refs/heads/") :]
        elif line == "detached":
            current["detached"] = "true"
        elif line == "" and current:
            worktrees.append(current)
            current = {}

    if current:
        worktrees.append(current)

    return worktrees


@click.command()
@click.option(
    "--dry-run",
    "-n",
    is_flag=True,
    help="Show what would be removed without removing",
)
def main(dry_run: bool) -> None:
    """Purge git worktrees whose branches are fully merged into main."""
    current_dir = Path(os.getcwd()).resolve()
    ghq_root = get_ghq_root()
    repos = find_repos(ghq_root)

    for repo in repos:
        main_branch = get_main_branch(repo)
        if not main_branch:
            continue
        worktrees = parse_worktrees(repo)

        for wt in worktrees:
            wt_path = Path(wt["path"])

            # Skip the main worktree
            if wt_path == repo:
                continue

            # Skip detached worktrees
            if wt.get("detached"):
                click.echo(f"skip (detached): {wt_path}")
                continue

            branch = wt.get("branch", "")
            if not branch:
                continue

            # Skip worktrees on the default branch
            if branch == main_branch:
                continue

            # Skip the worktree we're currently in
            try:
                if current_dir == wt_path or current_dir.is_relative_to(wt_path):
                    click.echo(f"skip (current): {branch} ({wt_path})")
                    continue
            except ValueError:
                pass

            if is_ancestor(repo, branch, main_branch):
                if dry_run:
                    click.echo(f"would remove: {branch} ({wt_path})")
                else:
                    click.echo(f"removing: {branch} ({wt_path})")
                    result = run(
                        ["git", "-C", str(repo), "worktree", "remove", str(wt_path)]
                    )
                    if result and result.returncode != 0:
                        click.echo(
                            f"  error: failed to remove worktree: {result.stderr.strip()}",
                            err=True,
                        )
                        continue
                    result = run(["git", "-C", str(repo), "branch", "-d", branch])
                    if result and result.returncode != 0:
                        click.echo(
                            f"  warning: worktree removed but branch delete failed: {result.stderr.strip()}",
                            err=True,
                        )
            else:
                click.echo(f"skip (not merged): {branch} ({wt_path})")


if __name__ == "__main__":
    main(prog_name="git-worktree-purge")
