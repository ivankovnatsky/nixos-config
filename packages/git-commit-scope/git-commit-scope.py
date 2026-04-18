#!/usr/bin/env python3

"""
Git commit subject scope helper that auto-generates scope from file or directory paths.
"""

import os
import re
import subprocess
import sys

import click

MACHINE_MAPPINGS = {
    "Ivans-Mac-mini": "mini",
    "Ivans-MacBook-Air": "air",
    "Ivans-MacBook-Pro": "pro",
    "Lusha-Macbook-Ivan-Kovnatskyi": "work",
}

DIRECTORY_MAPPINGS = {
    "packages": "pkg",
    "modules": "mod",
    "overlays": "ovl",
    "machines": "m",
    "darwin": "drw",
    "server": "srv",
    "service": "svc",
    "home": "hm",
    "nixvim": "nvim",
}

MAX_MESSAGE_LENGTH = 72


def get_git_root() -> str:
    """Get the root directory of the git repository."""
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def get_staged_files() -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--staged", "--name-only"],
        capture_output=True,
        text=True,
        check=True,
    )
    files = [f for f in result.stdout.strip().split("\n") if f]
    return files


def get_modified_files() -> list[str]:
    """Get tracked files that have been modified but not staged."""
    result = subprocess.run(
        ["git", "diff", "--name-only"],
        capture_output=True,
        text=True,
        check=True,
    )
    files = [f for f in result.stdout.strip().split("\n") if f]
    return files


def get_untracked_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files", "--others", "--exclude-standard"],
        capture_output=True,
        text=True,
        check=True,
    )
    files = [f for f in result.stdout.strip().split("\n") if f]
    return files


def get_all_changed_files() -> list[str]:
    """Get all changed files: staged + modified + untracked, deduplicated."""
    staged = get_staged_files()
    modified = get_modified_files()
    untracked = get_untracked_files()
    seen = dict()
    for f in staged + modified + untracked:
        if f not in seen:
            seen[f] = True
    return list(seen.keys())


def get_staged_renames() -> list[tuple[str, str]]:
    """Get pure staged renames (R100 only) as (old_path, new_path) pairs.

    Only matches R100 (identical content). Edited renames (R050, R075, etc.)
    are excluded so the commit message doesn't hide content changes.
    """
    result = subprocess.run(
        ["git", "diff", "--staged", "-M", "--diff-filter=R", "--name-status"],
        capture_output=True,
        text=True,
        check=True,
    )
    renames = []
    for line in result.stdout.strip().split("\n"):
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) >= 3 and parts[0] == "R100":
            renames.append((parts[1], parts[2]))
    return renames


def is_untracked(file_path: str, git_root: str) -> bool:
    """Check if a file is untracked by git."""
    result = subprocess.run(
        ["git", "ls-files", "--error-unmatch", file_path],
        capture_output=True,
        text=True,
        cwd=git_root,
    )
    return result.returncode != 0


def is_ignored(file_path: str, git_root: str) -> bool:
    """Check if a file is ignored by .gitignore."""
    result = subprocess.run(
        ["git", "check-ignore", "-q", file_path],
        capture_output=True,
        text=True,
        cwd=git_root,
    )
    return result.returncode == 0


def is_staged_path(path: str) -> bool:
    """Check if a path is in the staged files (works for deleted files too)."""
    try:
        result = subprocess.run(
            ["git", "diff", "--staged", "--name-only"],
            capture_output=True,
            text=True,
            check=True,
        )
        staged = [f for f in result.stdout.strip().split("\n") if f]
        # Normalize the input path for comparison
        abs_path = os.path.abspath(path)
        try:
            git_root = subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                capture_output=True,
                text=True,
                check=True,
            ).stdout.strip()
            rel_path = os.path.relpath(abs_path, git_root)
        except subprocess.CalledProcessError:
            rel_path = path
        return rel_path in staged or path in staged
    except subprocess.CalledProcessError:
        return False


def is_staged_deletion(path: str) -> bool:
    """Check if a path is staged as a deletion."""
    try:
        result = subprocess.run(
            ["git", "diff", "--staged", "--diff-filter=D", "--name-only"],
            capture_output=True,
            text=True,
            check=True,
        )
        deleted = [f for f in result.stdout.strip().split("\n") if f]
        abs_path = os.path.abspath(path)
        try:
            git_root = subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                capture_output=True,
                text=True,
                check=True,
            ).stdout.strip()
            rel_path = os.path.relpath(abs_path, git_root)
        except subprocess.CalledProcessError:
            rel_path = path
        return rel_path in deleted or path in deleted
    except subprocess.CalledProcessError:
        return False


def shorten_path(path: str) -> str:
    result = path

    # Strip file extension (requires word char before dot, e.g., file.py but not .gitconfig)
    result = re.sub(r"(?<=\w)\.[a-zA-Z0-9]+$", "", result)

    # Shorten machine names
    for long_name, short_name in MACHINE_MAPPINGS.items():
        result = result.replace(long_name, short_name)

    # Remove duplicate path component (e.g., packages/git-commit-scope/git-commit-scope -> packages/git-commit-scope)
    parts = result.split("/")
    if len(parts) >= 2 and parts[-1] == parts[-2]:
        result = "/".join(parts[:-1])

    # Strip "default" filename (default.nix is conventional entry point)
    parts = result.split("/")
    if len(parts) >= 2 and parts[-1] == "default":
        result = "/".join(parts[:-1])

    return result


def shorten_directories(path: str) -> str:
    """Apply aggressive directory shortening (packages->pkg, modules->mod, etc.)."""
    parts = path.split("/")
    shortened = [DIRECTORY_MAPPINGS.get(p, p) for p in parts]
    return "/".join(shortened)


def create_commit_message(prefix: str, subject: str) -> str:
    return f"{prefix}: {subject}"


def create_rename_message(old_path: str, new_path: str) -> str:
    """Create a commit message for a rename using arrow notation."""
    old_scope = shorten_path(old_path)
    new_scope = shorten_path(new_path)
    msg = f"{old_scope} -> {new_scope}"
    if len(msg) > MAX_MESSAGE_LENGTH:
        old_scope = shorten_directories(old_scope)
        new_scope = shorten_directories(new_scope)
        msg = f"{old_scope} -> {new_scope}"
    return msg


def _changes_are_only_renames(
    all_files: list[str], renames: list[tuple[str, str]]
) -> bool:
    """Check if all changed files are accounted for by renames."""
    if not renames:
        return False
    rename_paths = set()
    for old, new in renames:
        rename_paths.add(old)
        rename_paths.add(new)
    return all(f in rename_paths for f in all_files)


def _commit_renames(
    renames: list[tuple[str, str]], body_str: str | None, git_root: str
):
    """Commit staged renames with arrow notation messages."""
    os.environ["GIT_COMMIT_SCOPE_CLI"] = "1"
    if len(renames) > 1:
        click.echo("Multiple renames detected:", err=True)
        for old, new in renames:
            click.echo(f"  {old} -> {new}", err=True)
        click.echo(
            "Commit them individually or use git commit directly", err=True
        )
        sys.exit(1)
    old_path, new_path = renames[0]
    message = create_rename_message(old_path, new_path)
    if len(message) > MAX_MESSAGE_LENGTH:
        click.echo(
            f"Message too long: {len(message)} chars (max {MAX_MESSAGE_LENGTH})",
            err=True,
        )
        click.echo(f"Message: {message}", err=True)
        sys.exit(1)
    click.echo(f"  commit rename {old_path} -> {new_path}")
    cmd = ["git", "commit", "-m", message]
    if body_str:
        cmd.extend(["-m", body_str])
    try:
        subprocess.run(cmd, check=True, cwd=git_root)
    except subprocess.CalledProcessError as e:
        click.echo(f"Git commit failed: {e}", err=True)
        sys.exit(1)


def is_git_tracked(path: str) -> bool:
    """Check if a path is tracked by git (exists in index, even if deleted from disk)."""
    try:
        abs_path = os.path.abspath(path)
        git_root = get_git_root()
        rel_path = os.path.relpath(abs_path, git_root)
        result = subprocess.run(
            ["git", "ls-files", "--error-unmatch", rel_path],
            capture_output=True,
            text=True,
            cwd=git_root,
        )
        return result.returncode == 0
    except (subprocess.CalledProcessError, Exception):
        return False


def is_file_path(path: str) -> bool:
    """Check if path is a file (exists on disk, is staged, or is tracked by git).

    Checks both relative to CWD and relative to git root.
    """
    if os.path.exists(path) or is_staged_path(path) or is_git_tracked(path):
        return True
    # Also check relative to git root (handles paths like "packages/foo/bar.nix")
    try:
        git_root = get_git_root()
        abs_from_root = os.path.join(git_root, path)
        if os.path.exists(abs_from_root):
            return True
    except subprocess.CalledProcessError:
        pass
    return False


def _is_new_file(path: str) -> bool:
    """Check if a path is new to the repo (not in HEAD), for defaulting subject to 'init'.

    This covers both untracked files and staged-but-never-committed files.
    For directories, checks whether HEAD has any files under that path.
    """
    try:
        git_root = get_git_root()
        abs_path = os.path.abspath(path)
        rel_path = os.path.relpath(abs_path, git_root)
        if os.path.isdir(abs_path):
            # For directories, check if HEAD has any files under this path
            result = subprocess.run(
                ["git", "ls-tree", "-r", "HEAD", "--", rel_path],
                capture_output=True,
                text=True,
                cwd=git_root,
            )
            return result.returncode == 0 and not result.stdout.strip()
        result = subprocess.run(
            ["git", "cat-file", "-e", f"HEAD:{rel_path}"],
            capture_output=True,
            text=True,
            cwd=git_root,
        )
        return result.returncode != 0
    except subprocess.CalledProcessError:
        return False


def parse_args_flexible(
    args: list[str], subject_flag: str | None
) -> tuple[list[str], str]:
    """Parse arguments flexibly: one or more files + subject.

    Returns (file_paths, subject) where file_paths may be empty (auto-detect).
    Supports:
      - git-commit-scope "subject"                  -> ([], subject)
      - git-commit-scope file "subject"             -> ([file], subject)
      - git-commit-scope "subject" file             -> ([file], subject)
      - git-commit-scope file1 file2 "subject"      -> ([file1, file2], subject)
      - git-commit-scope file1 file2 -s "subject"   -> ([file1, file2], subject)
      - git-commit-scope file                       -> ([file], "init") if new file
    """
    if subject_flag:
        # Subject provided via -s flag — all positional args must be files
        files = []
        for a in args:
            if is_file_path(a):
                files.append(a)
            else:
                click.echo(f"Error: File not found: {a}", err=True)
                sys.exit(1)
        return files, subject_flag

    if len(args) == 0:
        click.echo("Error: Subject required (use -s or positional arg)", err=True)
        sys.exit(1)

    # Original behavior for 1 arg
    if len(args) == 1:
        if is_file_path(args[0]):
            if _is_new_file(args[0]):
                return [args[0]], "init"
            click.echo(
                f"Error: '{args[0]}' looks like a file path, not a subject.",
                err=True,
            )
            click.echo(
                "  Use: git-commit-scope <file> -s 'subject'",
                err=True,
            )
            click.echo(
                "  Or:  git-commit-scope <file> 'subject'",
                err=True,
            )
            sys.exit(1)
        return [], args[0]

    # 2+ args: separate files from subject
    # Exactly one non-file arg is the subject; rest are files
    files = []
    non_files = []
    for a in args:
        if is_file_path(a):
            files.append(a)
        else:
            non_files.append(a)

    if len(non_files) == 1:
        return files, non_files[0]
    elif len(non_files) == 0:
        click.echo("Error: All arguments are file paths, no subject provided", err=True)
        click.echo("  Use: git-commit-scope <file>... -s 'subject'", err=True)
        sys.exit(1)
    else:
        click.echo(
            "Error: Multiple non-file arguments (expected exactly one subject):",
            err=True,
        )
        for nf in non_files:
            click.echo(f"  {nf}", err=True)
        sys.exit(1)


@click.command(
    epilog="""\b
Examples:
  git-commit-scope "add feature"                     Commits staged file with "<scope>: add feature"
  git-commit-scope file.nix "add feature"            Commits file.nix with "<scope>: add feature"
  git-commit-scope src/dir "add feature"             Commits all changes in src/dir
  git-commit-scope f1.nix f2.nix "add feature"      Two separate commits, each with own scope
  git-commit-scope "add feature" -b "Body text"      Commits with subject and body
  git-commit-scope "add feature" -b "L1" -b "L2"     Multiple -b joined with newline
  git-commit-scope -s "add feature" -b "Line 1
  Line 2"                                       Multiline body with newlines
  git-commit-scope                                   After git mv: auto-detects rename, commits "old -> new"

Features:
  - Accepts one or more file/directory paths (auto-detected by existence)
  - Multiple files create separate commits, each with its own scope prefix
  - Directories commit all changes under that path
  - Auto-adds untracked files before committing
  - Without path arg, detects exactly one changed file (staged, modified, or untracked)
  - Strips file extensions (e.g., .nix, .py)
  - Shortens machine names (e.g., Ivans-Mac-mini -> mini)
  - Removes duplicate path components (e.g., pkg/foo/foo -> pkg/foo)
  - Strips "default" filename (e.g., mod/foo/default -> mod/foo)
  - Shortens directories if message > 72 chars (packages->pkg, modules->mod, etc.)
  - Detects staged renames (git mv) and commits with arrow notation (old -> new)
  - Validates total message length (max 72 chars)
""",
    context_settings={"help_option_names": ["-h", "--help"]},
)
@click.argument("args", nargs=-1, metavar="[PATH...] [SUBJECT]")
@click.option(
    "-s",
    "--subject",
    default=None,
    help="commit subject (alternative to positional arg)",
)
@click.option(
    "-b",
    "--body",
    multiple=True,
    help="commit body (can use multiple times, joined with newline)",
)
def main(args, subject, body):
    """Auto-generate git commit subject scope from changed file paths."""
    # Join multiple -b flags with single newline (no blank lines)
    body_str = "\n".join(body) if body else None

    # Get git root early - needed for path normalization and rename detection
    try:
        git_root = get_git_root()
    except subprocess.CalledProcessError as e:
        click.echo(f"Failed to get git root: {e}", err=True)
        sys.exit(1)

    # Handle rename-only mode: no args needed after git mv
    if not args and not subject:
        try:
            renames = get_staged_renames()
        except subprocess.CalledProcessError:
            renames = []
        if renames:
            try:
                all_files = get_all_changed_files()
            except subprocess.CalledProcessError:
                all_files = []
            if _changes_are_only_renames(all_files, renames):
                _commit_renames(renames, body_str, git_root)
                return
            else:
                rename_paths = set()
                for old, new in renames:
                    rename_paths.add(old)
                    rename_paths.add(new)
                other_files = [f for f in all_files if f not in rename_paths]
                click.echo(
                    "Staged renames found but also other changes:", err=True
                )
                click.echo("  Renames:", err=True)
                for old, new in renames:
                    click.echo(f"    {old} -> {new}", err=True)
                click.echo("  Other files:", err=True)
                for f in other_files:
                    click.echo(f"    {f}", err=True)
                click.echo(
                    "Commit the renames separately or specify files", err=True
                )
                sys.exit(1)

    file_paths, commit_subject = parse_args_flexible(list(args), subject)

    if file_paths:
        target_files = []
        for fp in file_paths:
            abs_path = os.path.abspath(fp)
            if not os.path.exists(abs_path):
                abs_from_root = os.path.join(git_root, fp)
                if os.path.exists(abs_from_root):
                    abs_path = os.path.abspath(abs_from_root)
            target_files.append(os.path.relpath(abs_path, git_root))
    else:
        try:
            all_files = get_all_changed_files()
        except subprocess.CalledProcessError as e:
            click.echo(f"Failed to get changed files: {e}", err=True)
            sys.exit(1)

        if not all_files:
            click.echo("No changed files", err=True)
            sys.exit(1)

        if len(all_files) != 1:
            # Check if changes are all renames
            try:
                renames = get_staged_renames()
            except subprocess.CalledProcessError:
                renames = []
            if _changes_are_only_renames(all_files, renames):
                _commit_renames(renames, body_str, git_root)
                return

            click.echo(
                f"Expected 1 changed file, found {len(all_files)}:",
                err=True,
            )
            for f in all_files:
                click.echo(f"  {f}", err=True)
            sys.exit(1)

        target_files = [all_files[0]]

    # Set env var so pre-commit hook skips the "use git-commit-scope" hint
    os.environ["GIT_COMMIT_SCOPE_CLI"] = "1"

    def _too_long(p: str) -> bool:
        return len(create_commit_message(p, commit_subject)) > MAX_MESSAGE_LENGTH

    for target_file in target_files:
        prefix = shorten_path(target_file)

        if _too_long(prefix):
            prefix = shorten_directories(prefix)

        if _too_long(prefix):
            full_msg = create_commit_message(prefix, commit_subject)
            max_subject = MAX_MESSAGE_LENGTH - len(prefix) - len(": ")
            click.echo(
                f"Message too long: {len(full_msg)} chars (max {MAX_MESSAGE_LENGTH})",
                err=True,
            )
            click.echo(f"Scope: {prefix}", err=True)
            click.echo(
                f"Subject must be ≤ {max_subject} chars (currently {len(commit_subject)})",
                err=True,
            )
            sys.exit(1)

        message = create_commit_message(prefix, commit_subject)

        try:
            # Add untracked files first (git commit <file> only works for tracked files)
            # Skip if file is already staged (e.g., staged deletion)
            force_added = False
            if is_staged_path(target_file):
                # File already staged — check if it's ignored (e.g., pre-staged with git add -f)
                force_added = is_ignored(target_file, git_root)
            elif is_untracked(target_file, git_root):
                result = subprocess.run(
                    ["git", "add", target_file],
                    capture_output=True,
                    text=True,
                    cwd=git_root,
                )
                if result.returncode != 0:
                    # Fall back to force-add (needed when .gitignore ignores the file)
                    click.echo(f"  add -f {target_file}")
                    subprocess.run(
                        ["git", "add", "-f", target_file], check=True, cwd=git_root
                    )
                    force_added = True
                else:
                    click.echo(f"  add {target_file}")

            click.echo(f"  commit {target_file}")

            # For staged deletions, git commit <file> doesn't work because it reads
            # from the working tree (where the file no longer exists). Use --only
            # to commit just this path from the index without pulling in other staged changes.
            if is_staged_deletion(target_file):
                cmd = ["git", "commit", "--only", target_file, "-m", message]
            elif force_added:
                # Ignored files can't be used as pathspec (git respects .gitignore
                # in pathspec matching even after git add -f). Commit from index.
                cmd = ["git", "commit", "-m", message]
            else:
                cmd = ["git", "commit", target_file, "-m", message]
            if body_str:
                cmd.extend(["-m", body_str])
            subprocess.run(cmd, check=True, cwd=git_root)
        except subprocess.CalledProcessError as e:
            click.echo(f"Git commit failed: {e}", err=True)
            sys.exit(1)


if __name__ == "__main__":
    main(prog_name="git-commit-scope")
