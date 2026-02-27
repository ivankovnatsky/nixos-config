#!/usr/bin/env python3
"""Git dotfiles management tool.

Modes:
  home      Bare repo + Syncthing sync across machines
  work      Local-only ~/.git backup (no sync)
  shared    Symlink-based shared dotfiles across all machines

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

  dotfiles shared init          Initialize shared dotfiles repo
  dotfiles shared deploy        Create symlinks from repo to ~/
  dotfiles shared status        Show deployed vs missing symlinks
  dotfiles shared add <file>    Move ~/file into repo and symlink back
"""

import argparse
import json
import platform
import shutil
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
BARE_REPO = HOME / "Sources/github.com/ivankovnatsky-local/dotfiles"
SHARED_REPO = HOME / "Sources/github.com/ivankovnatsky-local/dotfiles-shared"
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


def run_git(
    *args: str, cwd: Path = HOME, check: bool = True, timeout: int = GIT_TIMEOUT
) -> subprocess.CompletedProcess:
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
    unpushed = (
        int(result.stdout.strip())
        if result.returncode == 0 and result.stdout.strip()
        else 0
    )

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
    """Pull changes from bare repo. Fast-forward only, aborts if merge needed."""
    result = run_git("pull", "--ff-only")
    if result.returncode != 0:
        print("Error: Pull requires merge. Resolve manually.", file=sys.stderr)
        return 1
    print(result.stdout.strip())
    return 0


def cmd_home_sync(args: argparse.Namespace) -> int:
    """Sync: init + pull + push."""
    if has_git_lock():
        print(
            "Error: Git lock file exists, another process may be running.",
            file=sys.stderr,
        )
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


# ============ SHARED MODE (symlink-based cross-machine dotfiles) ============

SHARED_DIRS = ["common", "work", "home"]

DEFAULT_MACHINES_JSON = {
    "Lusha-Macbook-Ivan-Kovnatskyi": "work",
    "Ivans-MacBook-Air": "home",
    "Ivans-MacBook-Pro": "home",
    "Ivans-Mac-mini": "home",
    "a3": "home",
    "steamdeck": "home",
}


def get_hostname() -> str:
    """Get local hostname (matches Syncthing/Nix hostnames)."""
    return platform.node()


def get_machine_purpose() -> str | None:
    """Read purpose for this machine from machines.json."""
    machines_file = SHARED_REPO / "machines.json"
    if not machines_file.exists():
        return None
    try:
        machines = json.loads(machines_file.read_text())
    except (json.JSONDecodeError, OSError):
        return None
    hostname = get_hostname()
    return machines.get(hostname)


def iter_repo_files(subdir: Path):
    """Yield (repo_file, home_relative_path) for all files in a subdir."""
    if not subdir.is_dir():
        return
    for path in sorted(subdir.rglob("*")):
        if path.is_file() and ".git" not in path.parts and path.name != ".gitkeep":
            rel = path.relative_to(subdir)
            yield path, rel


def deploy_symlink(repo_file: Path, home_rel: Path) -> str | None:
    """Create symlink from ~/<home_rel> -> repo_file. Returns status message or None."""
    target = HOME / home_rel
    if target.is_symlink():
        if target.resolve() == repo_file.resolve():
            return None
        target.unlink()
        target.symlink_to(repo_file)
        return f"  updated: {home_rel}"
    if target.exists():
        return f"  CONFLICT: {home_rel} (exists, not a symlink)"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.symlink_to(repo_file)
    return f"  linked: {home_rel}"


def cmd_shared_init(args: argparse.Namespace) -> int:
    """Initialize shared dotfiles repo."""
    changed = False

    if not SHARED_REPO.exists():
        SHARED_REPO.mkdir(parents=True)
        changed = True

    if not (SHARED_REPO / ".git").exists():
        run_git("init", cwd=SHARED_REPO)
        print(f"Initialized git repo at {SHARED_REPO}")
        changed = True

    for d in SHARED_DIRS:
        dirpath = SHARED_REPO / d
        if not dirpath.exists():
            dirpath.mkdir()
            (dirpath / ".gitkeep").touch()
            changed = True

    machines_file = SHARED_REPO / "machines.json"
    if not machines_file.exists():
        machines_file.write_text(json.dumps(DEFAULT_MACHINES_JSON, indent=2) + "\n")
        print(f"Created {machines_file}")
        changed = True

    readme = SHARED_REPO / "README.md"
    if not readme.exists():
        readme.write_text(
            "# dotfiles-shared\n\n"
            "Shared dotfiles synced to all machines via Syncthing.\n\n"
            "Structure:\n"
            "- `common/` - deployed to all machines\n"
            "- `work/` - deployed when machine purpose is work\n"
            "- `home/` - deployed when machine purpose is home\n\n"
            "Files mirror `~/` paths. Run `dotfiles shared deploy` to create symlinks.\n"
        )
        changed = True

    # Create initial commit if repo has no commits yet
    result = run_git("rev-parse", "HEAD", cwd=SHARED_REPO, check=False)
    if result.returncode != 0:
        init_files = ["README.md", "machines.json", "common/", "work/", "home/"]
        result = run_git("add", *init_files, cwd=SHARED_REPO)
        if result.returncode != 0:
            return 1
        result = run_git("commit", *init_files, "-m", "Init", cwd=SHARED_REPO)
        if result.returncode != 0:
            return 1
        print(result.stdout.strip())
        changed = True

    if changed:
        print("Shared dotfiles repo initialized.")
    else:
        print("Already initialized.")
    return 0


def cmd_shared_deploy(args: argparse.Namespace) -> int:
    """Deploy symlinks from shared repo to ~/."""
    if not SHARED_REPO.exists():
        print(
            "Error: Shared repo not found. Run 'dotfiles shared init' first.",
            file=sys.stderr,
        )
        return 1

    purpose = get_machine_purpose()
    hostname = get_hostname()
    messages = []

    for repo_file, rel in iter_repo_files(SHARED_REPO / "common"):
        msg = deploy_symlink(repo_file, rel)
        if msg:
            messages.append(msg)

    if purpose:
        purpose_dir = SHARED_REPO / purpose
        for repo_file, rel in iter_repo_files(purpose_dir):
            msg = deploy_symlink(repo_file, rel)
            if msg:
                messages.append(msg)
    elif purpose is None:
        print(
            f"Warning: hostname '{hostname}' not in machines.json, deploying common/ only",
            file=sys.stderr,
        )

    if messages:
        print("Deploy results:")
        for msg in messages:
            print(msg)
    else:
        print("All symlinks up to date.")
    return 0


def cmd_shared_status(args: argparse.Namespace) -> int:
    """Show status of shared dotfiles symlinks."""
    if not SHARED_REPO.exists():
        print(
            "Error: Shared repo not found. Run 'dotfiles shared init' first.",
            file=sys.stderr,
        )
        return 1

    purpose = get_machine_purpose()
    hostname = get_hostname()
    ok_count = 0
    issues = []

    dirs_to_check = [SHARED_REPO / "common"]
    if purpose:
        dirs_to_check.append(SHARED_REPO / purpose)

    for check_dir in dirs_to_check:
        for repo_file, rel in iter_repo_files(check_dir):
            target = HOME / rel
            if target.is_symlink():
                if target.resolve() == repo_file.resolve():
                    ok_count += 1
                else:
                    issues.append(f"  wrong target: {rel} -> {target.readlink()}")
            elif target.exists():
                issues.append(f"  CONFLICT: {rel} (exists, not a symlink)")
            else:
                issues.append(f"  missing: {rel}")

    label = f"common + {purpose}" if purpose else "common only"
    if not purpose:
        print(f"Warning: hostname '{hostname}' not in machines.json", file=sys.stderr)

    if issues:
        print(f"Status ({label}): {ok_count} ok, {len(issues)} issue(s)")
        for issue in issues:
            print(issue)
        return 1
    print(f"Status ({label}): {ok_count} symlink(s) ok")
    return 0


def cmd_shared_add(args: argparse.Namespace) -> int:
    """Move a file from ~/ into the shared repo and symlink back."""
    if not SHARED_REPO.exists():
        print(
            "Error: Shared repo not found. Run 'dotfiles shared init' first.",
            file=sys.stderr,
        )
        return 1

    file_path = Path(args.file).expanduser().resolve()
    if not file_path.exists():
        print(f"Error: {args.file} does not exist.", file=sys.stderr)
        return 1
    if file_path.is_symlink():
        print(f"Error: {args.file} is already a symlink.", file=sys.stderr)
        return 1

    try:
        rel = file_path.relative_to(HOME)
    except ValueError:
        print(f"Error: {args.file} is not under ~/", file=sys.stderr)
        return 1

    category = (
        args.category if hasattr(args, "category") and args.category else "common"
    )
    if category not in SHARED_DIRS:
        print(f"Error: category must be one of {SHARED_DIRS}", file=sys.stderr)
        return 1

    dest = SHARED_REPO / category / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(file_path), str(dest))
    file_path.symlink_to(dest)
    print(f"Moved {rel} -> {category}/{rel}")
    print(f"Symlinked ~/{rel} -> {dest}")
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

    # Shared mode
    shared_parser = subparsers.add_parser(
        "shared", help="Symlink-based shared dotfiles"
    )
    shared_sub = shared_parser.add_subparsers(dest="command")

    shared_sub.add_parser("init", help="Initialize shared dotfiles repo")
    shared_sub.add_parser("deploy", help="Create symlinks from repo to ~/")
    shared_sub.add_parser("status", help="Show deployed vs missing symlinks")

    shared_add = shared_sub.add_parser(
        "add", help="Move ~/file into repo and symlink back"
    )
    shared_add.add_argument("file", help="File to add (relative to ~ or absolute)")
    shared_add.add_argument(
        "-c",
        "--category",
        default="common",
        choices=SHARED_DIRS,
        help="Target category (default: common)",
    )

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

    if args.mode == "shared":
        if not args.command:
            shared_parser.print_help()
            return 0
        commands = {
            "init": cmd_shared_init,
            "deploy": cmd_shared_deploy,
            "status": cmd_shared_status,
            "add": cmd_shared_add,
        }
        return commands[args.command](args)

    return 0


if __name__ == "__main__":
    sys.exit(main())
