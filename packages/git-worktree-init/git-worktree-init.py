#!/usr/bin/env python3
"""
Git worktree initialization tool.

Creates or navigates to a git worktree for the specified branch.
Worktrees are created at ~/Worktrees/<host>/<repo>/<branch-name> (slashes replaced with dashes).
"""

import os
import re
import subprocess
import sys
from pathlib import Path

import click


DEFAULT_CHAR_LIMIT = 35
DEFAULT_WORKTREE_ROOT = Path.home() / "Worktrees"


def get_repo_identifier() -> str:
    """Derive a repo identifier from the remote URL or local path.

    For remote repos, extracts host/org/repo (e.g., github.com/lusha-com/infra).
    For local repos, uses the path relative to HOME.
    """
    remote_url = run_git("remote", "get-url", "origin", check=False)
    if remote_url:
        # Handle SSH: git@github.com:org/repo.git
        match = re.match(r"git@([^:]+):(.+?)(?:\.git)?$", remote_url)
        if match:
            host = match.group(1)
            path = match.group(2)
            return f"{host}/{path}"
        # Handle HTTPS: https://github.com/org/repo.git
        match = re.match(r"https?://([^/]+)/(.+?)(?:\.git)?$", remote_url)
        if match:
            host = match.group(1)
            path = match.group(2)
            return f"{host}/{path}"

    # Fallback: use path relative to HOME
    root = get_real_git_root()
    if root:
        rel = str(root).replace(str(Path.home()), "").strip("/")
        return rel if rel else "local"
    return "local"


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


def strip_remote_prefix(branch: str) -> str:
    """Strip remote prefix (e.g., origin/, upstream/) from branch name."""
    match = re.match(r"^(origin|upstream|remote)/(.+)$", branch)
    if match:
        return match.group(2)
    return branch


def extract_remote_name(ref: str) -> str | None:
    """Extract remote name from a ref like 'origin/branch' or 'upstream/branch'."""
    match = re.match(r"^([a-zA-Z0-9_-]+)/", ref)
    if match:
        remote = match.group(1)
        remotes = run_git("remote").split("\n")
        if remote in remotes:
            return remote
    return None


def fetch_remote(remote: str, ref: str) -> bool:
    """Fetch a specific ref from a remote."""
    branch = strip_remote_prefix(ref)
    result = run_git("fetch", remote, branch, check=False)
    return result is not None


def process_branch_name(
    branch: str,
    char_limit: int,
    no_trim: bool,
    sha_suffix: bool,
    current_sha: str | None,
) -> str:
    """Process branch name with optional trimming and SHA suffix."""
    branch = strip_remote_prefix(branch)
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


def find_worktree_by_branch(branch: str) -> Path | None:
    """Find an existing worktree path for the given branch using git worktree list."""
    output = run_git("worktree", "list", "--porcelain", check=False)
    if not output:
        return None

    current_path = None
    for line in output.splitlines():
        if line.startswith("worktree "):
            current_path = line[len("worktree ") :]
        elif line.startswith("branch refs/heads/") and current_path:
            wt_branch = line[len("branch refs/heads/") :]
            if wt_branch == branch:
                return Path(current_path)
        elif line == "":
            current_path = None

    return None


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


def create_worktree(
    worktree_dir: Path,
    branch: str,
    base_branch: str | None,
    extra_args: list[str] | None = None,
) -> bool:
    """Create a git worktree."""
    worktree_dir.parent.mkdir(parents=True, exist_ok=True)
    extra = extra_args or []

    if branch_exists(branch):
        run_git("worktree", "add", *extra, str(worktree_dir), branch, check=False)
    else:
        if base_branch:
            run_git(
                "worktree",
                "add",
                *extra,
                "-b",
                branch,
                str(worktree_dir),
                base_branch,
                check=False,
            )
        else:
            run_git(
                "worktree", "add", *extra, "-b", branch, str(worktree_dir), check=False
            )

    return worktree_dir.exists()


@click.command(
    epilog="""
The worktree is created at ~/Worktrees/<host>/<org>/<repo>/<branch-name>
where slashes in the branch name are replaced with dashes (e.g.,
feature/PROJ-123 -> feature-PROJ-123). If the branch doesn't exist,
it will be created.

\b
Example:
  git-worktree-init feature/PROJ-12345-some-description
  git-worktree-init feature/CIN-907 origin/feature/CIN-907-initial-setup
  git-worktree-init --no-pull feature/quick-fix
  git-worktree-init --sha-suffix feature/TICKET-123
  git-worktree-init feature/branch -- --track --force
""",
)
@click.argument("branch")
@click.argument("start_point", required=False, default=None)
@click.option(
    "--no-trim",
    is_flag=True,
    default=False,
    help="Disable branch name trimming (default: trim enabled)",
)
@click.option(
    "--char-limit",
    type=int,
    default=DEFAULT_CHAR_LIMIT,
    show_default=True,
    help="Character limit for branch name part",
)
@click.option(
    "--sha-suffix",
    is_flag=True,
    default=False,
    help="Append 7-char SHA to branch name for uniqueness (default: disabled)",
)
@click.option(
    "--no-pull",
    is_flag=True,
    default=False,
    help="Skip checkout and pull of default branch (default: pull enabled)",
)
@click.argument("git_args", nargs=-1)
def main(
    branch: str,
    start_point: str | None,
    no_trim: bool,
    char_limit: int,
    sha_suffix: bool,
    no_pull: bool,
    git_args: tuple[str, ...],
) -> None:
    """Create or navigate to a git worktree for the specified branch.

    BRANCH is the branch name for the worktree (e.g., feature/TICKET-123).
    Remote prefixes like origin/ are stripped.

    START_POINT is an optional start point (e.g., origin/feature/TICKET-123)
    to base the new branch on.

    Worktrees are placed at ~/Worktrees/<host>/<org>/<repo>/<branch>
    (slashes in branch name replaced with dashes).
    """
    git_root = get_git_root()
    if not git_root:
        click.echo("Error: Not in a git repository", err=True)
        sys.exit(1)

    real_git_root = get_real_git_root()
    if not real_git_root:
        click.echo("Error: Could not determine git root", err=True)
        sys.exit(1)

    git_dir = get_git_common_dir()
    if not git_dir:
        click.echo("Error: Could not determine git directory", err=True)
        sys.exit(1)

    os.chdir(real_git_root)

    default_branch = get_default_branch()
    current_sha = None

    if not no_pull:
        if default_branch:
            run_git("checkout", default_branch, check=False)
            run_git("pull", "origin", default_branch, check=False)
            current_sha = run_git("rev-parse", "HEAD")
        else:
            current_sha = run_git("rev-parse", "HEAD")
    else:
        current_sha = run_git("rev-parse", "HEAD")

    effective_no_trim = no_trim or start_point is not None
    branch_name = process_branch_name(
        branch,
        char_limit,
        effective_no_trim,
        sha_suffix,
        current_sha,
    )

    # Check if branch already has a worktree (handles old and new path formats)
    existing = find_worktree_by_branch(branch_name)
    if existing and existing.exists():
        click.echo(str(existing), nl=False)
        return

    repo_id = get_repo_identifier()
    dir_name = branch_name.replace("/", "-")
    worktree_dir = DEFAULT_WORKTREE_ROOT / repo_id / dir_name

    # Fallback: check old slash-separated path for backward compatibility
    old_worktree_dir = DEFAULT_WORKTREE_ROOT / repo_id / branch_name
    if old_worktree_dir.exists():
        click.echo(str(old_worktree_dir), nl=False)
        return

    if worktree_dir.exists():
        click.echo(str(worktree_dir), nl=False)
        return

    base_branch = start_point if start_point else default_branch

    if start_point:
        remote = extract_remote_name(start_point)
        if remote:
            fetch_remote(remote, start_point)

    if not create_worktree(worktree_dir, branch_name, base_branch, list(git_args)):
        click.echo(f"Error: Failed to create worktree at {worktree_dir}", err=True)
        sys.exit(1)

    click.echo(str(worktree_dir), nl=False)


if __name__ == "__main__":
    main(prog_name="git-worktree-init")
