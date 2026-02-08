#!/usr/bin/env python3
"""Git dotfiles management tool.

Modes:
  home    Bare repo + Syncthing sync across machines
  work    Local-only ~/.git backup (no sync)

Commands:
  dotfiles home init     Set up bare repo (idempotent)
  dotfiles home push     Push committed changes to bare repo (no auto-commit)
  dotfiles home pull     Pull from bare repo
  dotfiles home sync     Init + pull + push (for automation)
  dotfiles home status   Show git status

  dotfiles work init     Initialize local ~/.git
  dotfiles work status   Show git status
  dotfiles work add      Add files to staging
  dotfiles work commit   Commit staged changes
"""

import argparse
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
BARE_REPO = HOME / "Sources/github.com/ivankovnatsky-local/dotfiles"
GIT_DIR = HOME / ".git"
GIT_TIMEOUT = 60  # seconds

MANAGED_FILES = {
    ".gitignore": "**\n",
}


def has_git_lock() -> bool:
    """Check if git lock file exists (another git process running)."""
    lock_files = ["index.lock", "HEAD.lock", "config.lock"]
    for lock in lock_files:
        if (GIT_DIR / lock).exists():
            return True
    return False


def run_git(*args: str, cwd: Path = HOME, check: bool = True, timeout: int = GIT_TIMEOUT) -> subprocess.CompletedProcess:
    """Run git command in specified directory."""
    try:
        result = subprocess.run(
            ["git"] + list(args),
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        print(f"Error: git {args[0]} timed out after {timeout}s", file=sys.stderr)
        return subprocess.CompletedProcess(args, 1, "", "timeout")
    if check and result.returncode != 0:
        print(f"Error: {result.stderr.strip()}", file=sys.stderr)
    return result


def apply_files() -> None:
    """Apply managed files if they don't exist."""
    for filename, content in MANAGED_FILES.items():
        path = HOME / filename
        if not path.exists():
            path.write_text(content)
            print(f"Created {path}")


# ============ HOME MODE (bare repo + sync) ============


def cmd_home_init(args: argparse.Namespace) -> int:
    """Initialize home mode with bare repo."""
    changed = False

    # Step 1: Ensure ~/.git exists
    if not GIT_DIR.exists():
        print("Initializing ~/.git...")
        result = run_git("init")
        if result.returncode != 0:
            return 1
        changed = True

    # Step 2: Create bare repo if needed
    if not BARE_REPO.exists():
        print(f"Creating bare repo at {BARE_REPO}...")
        BARE_REPO.parent.mkdir(parents=True, exist_ok=True)
        result = run_git("clone", "--bare", str(GIT_DIR), str(BARE_REPO))
        if result.returncode != 0:
            return 1
        print(f"Created bare repo: {BARE_REPO}")
        changed = True

    # Step 3: Configure remote
    result = run_git("remote", "get-url", "origin", check=False)
    if result.returncode != 0:
        run_git("remote", "add", "origin", str(BARE_REPO))
        print(f"Added remote origin -> {BARE_REPO}")
        changed = True
    elif result.stdout.strip() != str(BARE_REPO):
        run_git("remote", "set-url", "origin", str(BARE_REPO))
        print(f"Updated remote origin -> {BARE_REPO}")
        changed = True

    # Step 4: Fetch and set upstream
    run_git("fetch", "origin", check=False)

    # Check if main branch exists
    result = run_git("rev-parse", "--verify", "main", check=False)
    if result.returncode == 0:
        run_git("branch", "-u", "origin/main", "main", check=False)
    else:
        result = run_git("rev-parse", "--verify", "origin/main", check=False)
        if result.returncode == 0:
            run_git("checkout", "-b", "main", "--track", "origin/main", check=False)
            print("Created main branch tracking origin/main")
            changed = True

    apply_files()

    if changed:
        print("Home mode initialized.")
    else:
        print("Already initialized.")
    return 0


def cmd_home_push(args: argparse.Namespace) -> int:
    """Push already committed changes to bare repo. Does NOT auto-commit."""
    # Check for unpushed commits
    result = run_git("rev-list", "--count", "origin/main..HEAD", check=False)
    unpushed = int(result.stdout.strip()) if result.returncode == 0 and result.stdout.strip() else 0

    if unpushed == 0:
        print("Nothing to push.")
        return 0

    # Push
    result = run_git("push", "-u", "origin", "main")
    if result.returncode != 0:
        return 1
    print(f"Pushed {unpushed} commit(s) to bare repo.")
    return 0


def cmd_home_pull(args: argparse.Namespace) -> int:
    """Pull changes from bare repo."""
    result = run_git("pull")
    if result.returncode != 0:
        return 1
    print(result.stdout.strip())
    return 0


def cmd_home_sync(args: argparse.Namespace) -> int:
    """Sync: init + pull + push."""
    if has_git_lock():
        print("Error: Git lock file exists, another process may be running.", file=sys.stderr)
        return 1
    if cmd_home_init(args) != 0:
        return 1
    if cmd_home_pull(args) != 0:
        return 1
    if cmd_home_push(args) != 0:
        return 1
    return 0


def cmd_home_status(args: argparse.Namespace) -> int:
    """Show git status."""
    result = run_git("status", "--short", check=False)
    print(result.stdout, end="")
    return result.returncode


# ============ WORK MODE (local-only) ============


def cmd_work_init(args: argparse.Namespace) -> int:
    """Initialize work mode (local only)."""
    changed = False
    if GIT_DIR.exists():
        pass
    else:
        result = run_git("init")
        if result.returncode != 0:
            return 1
        print(result.stdout.strip())
        changed = True

    apply_files()

    if changed:
        print("Work mode initialized (local only, no sync).")
    else:
        print("Already initialized.")
    return 0


def cmd_work_status(args: argparse.Namespace) -> int:
    """Show git status."""
    result = run_git("status", "--short", check=False)
    print(result.stdout, end="")
    return result.returncode


def cmd_work_add(args: argparse.Namespace) -> int:
    """Add files to staging."""
    if not args.files:
        print("Error: No files specified.", file=sys.stderr)
        return 1
    result = run_git("add", *args.files)
    return result.returncode


def cmd_work_commit(args: argparse.Namespace) -> int:
    """Commit staged changes."""
    msg = args.message if args.message else "Update dotfiles"
    result = run_git("commit", "-m", msg)
    if result.returncode != 0:
        return 1
    print(result.stdout.strip())
    return 0


# ============ MAIN ============


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Git dotfiles management tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    subparsers = parser.add_subparsers(dest="mode", help="Mode")

    # Home mode
    home_parser = subparsers.add_parser("home", help="Bare repo + Syncthing sync")
    home_sub = home_parser.add_subparsers(dest="command")

    home_sub.add_parser("init", help="Initialize bare repo setup (idempotent)")
    home_sub.add_parser("push", help="Push committed changes to bare repo")
    home_sub.add_parser("pull", help="Pull from bare repo")
    home_sub.add_parser("sync", help="Init + push + pull (for automation)")
    home_sub.add_parser("status", help="Show git status")

    # Work mode
    work_parser = subparsers.add_parser("work", help="Local-only backup (no sync)")
    work_sub = work_parser.add_subparsers(dest="command")

    work_sub.add_parser("init", help="Initialize local ~/.git")
    work_sub.add_parser("status", help="Show git status")

    work_add = work_sub.add_parser("add", help="Add files to staging")
    work_add.add_argument("files", nargs="*", help="Files to add")

    work_commit = work_sub.add_parser("commit", help="Commit staged changes")
    work_commit.add_argument("-m", "--message", help="Commit message")

    args = parser.parse_args()

    if not args.mode:
        parser.print_help()
        return 0

    if args.mode == "home":
        if not args.command:
            home_parser.print_help()
            return 0
        commands = {
            "init": cmd_home_init,
            "push": cmd_home_push,
            "pull": cmd_home_pull,
            "sync": cmd_home_sync,
            "status": cmd_home_status,
        }
        return commands[args.command](args)

    if args.mode == "work":
        if not args.command:
            work_parser.print_help()
            return 0
        commands = {
            "init": cmd_work_init,
            "status": cmd_work_status,
            "add": cmd_work_add,
            "commit": cmd_work_commit,
        }
        return commands[args.command](args)

    return 0


if __name__ == "__main__":
    sys.exit(main())
