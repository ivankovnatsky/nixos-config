#!/usr/bin/env python3

"""
Git commit subject scope helper that auto-generates scope from file or directory paths.
"""

import argparse
import os
import re
import subprocess
import sys

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
MAX_PREFIX_LENGTH = 36


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


def is_untracked(file_path: str, git_root: str) -> bool:
    """Check if a file is untracked by git."""
    result = subprocess.run(
        ["git", "ls-files", "--error-unmatch", file_path],
        capture_output=True,
        text=True,
        cwd=git_root,
    )
    return result.returncode != 0


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


def shorten_path(path: str) -> str:
    result = path

    # Strip file extension (requires word char before dot, e.g., file.py but not .gitconfig)
    result = re.sub(r"(?<=\w)\.[a-zA-Z0-9]+$", "", result)

    # Shorten machine names
    for long_name, short_name in MACHINE_MAPPINGS.items():
        result = result.replace(long_name, short_name)

    # Remove duplicate path component (e.g., packages/git-message/git-message -> packages/git-message)
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


def collapse_middle(path: str) -> str:
    """Collapse middle path segments to * keeping first and last.

    Example: a/b/c/d/e -> a/*/e
    """
    parts = path.split("/")
    if len(parts) <= 2:
        return path
    return f"{parts[0]}/*/{parts[-1]}"


def create_commit_message(prefix: str, subject: str) -> str:
    return f"{prefix}: {subject}"


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


def _is_untracked_file(path: str) -> bool:
    """Check if a path is an untracked file (for defaulting subject to 'init')."""
    try:
        git_root = get_git_root()
        abs_path = os.path.abspath(path)
        rel_path = os.path.relpath(abs_path, git_root)
        result = subprocess.run(
            ["git", "ls-files", "--error-unmatch", rel_path],
            capture_output=True,
            text=True,
            cwd=git_root,
        )
        return result.returncode != 0
    except subprocess.CalledProcessError:
        return False


def parse_args_flexible(
    args: list[str], subject_flag: str | None
) -> tuple[str | None, str]:
    """Parse arguments flexibly: file can be before or after subject."""
    if subject_flag:
        # Subject provided via -s flag
        if len(args) == 0:
            return None, subject_flag
        elif len(args) == 1:
            if is_file_path(args[0]):
                return args[0], subject_flag
            else:
                print(f"Error: File not found: {args[0]}", file=sys.stderr)
                sys.exit(1)
        else:
            print("Error: Too many positional args with -s flag", file=sys.stderr)
            sys.exit(1)

    # Original behavior: subject from positional args
    if len(args) == 1:
        if is_file_path(args[0]):
            # Default to "init" for untracked files when no subject given
            if _is_untracked_file(args[0]):
                return args[0], "init"
            print(
                f"Error: '{args[0]}' looks like a file path, not a subject.",
                file=sys.stderr,
            )
            print(
                "  Use: git-message <file> -s 'subject'",
                file=sys.stderr,
            )
            print(
                "  Or:  git-message <file> 'subject'",
                file=sys.stderr,
            )
            sys.exit(1)
        return None, args[0]
    elif len(args) == 2:
        # Check which argument is a file (exists on disk or staged)
        first_is_file = is_file_path(args[0])
        second_is_file = is_file_path(args[1])

        if first_is_file and not second_is_file:
            return args[0], args[1]
        elif second_is_file and not first_is_file:
            return args[1], args[0]
        elif first_is_file and second_is_file:
            print("Error: Both arguments are file paths", file=sys.stderr)
            sys.exit(1)
        else:
            print("Error: Neither argument is a file path", file=sys.stderr)
            print(f"  {args[0]}", file=sys.stderr)
            print(f"  {args[1]}", file=sys.stderr)
            sys.exit(1)
    elif len(args) == 0:
        print("Error: Subject required (use -s or positional arg)", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"Error: Expected 1 or 2 arguments, got {len(args)}", file=sys.stderr)
        sys.exit(1)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Auto-generate git commit subject scope from changed file paths.",
        epilog="""
Examples:
  git-message "add feature"                     Commits staged file with "<scope>: add feature"
  git-message file.nix "add feature"            Commits file.nix with "<scope>: add feature"
  git-message src/dir "add feature"             Commits all changes in src/dir
  git-message "add feature" -b "Body text"      Commits with subject and body
  git-message "add feature" -b "L1" -b "L2"     Multiple -b joined with newline
  git-message -s "add feature" -b "Line 1
  Line 2"                                       Multiline body with newlines

Features:
  - Accepts file or directory path in either position (auto-detected by existence)
  - Directories commit all changes under that path
  - Auto-adds untracked files before committing
  - Without path arg, detects exactly one changed file (staged, modified, or untracked)
  - Strips file extensions (e.g., .nix, .py)
  - Shortens machine names (e.g., Ivans-Mac-mini -> mini)
  - Removes duplicate path components (e.g., pkg/foo/foo -> pkg/foo)
  - Strips "default" filename (e.g., mod/foo/default -> mod/foo)
  - Shortens directories if scope > 36 (packages->pkg, modules->mod, etc.)
  - Collapses middle path segments to * if still too long (a/b/c/d -> a/*/d)
  - Validates scope length (max 36 chars)
  - Validates subject length (max 72 chars)
""",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "args", nargs="*", help="subject and optional file/directory path (in any order)"
    )
    parser.add_argument(
        "-s", "--subject", help="commit subject (alternative to positional arg)"
    )
    parser.add_argument(
        "-b",
        "--body",
        action="append",
        help="commit body (can use multiple times, joined with newline)",
    )
    parsed = parser.parse_args()

    # Join multiple -b flags with single newline (no blank lines)
    body = "\n".join(parsed.body) if parsed.body else None

    file_path, subject = parse_args_flexible(parsed.args, parsed.subject)

    # Get git root early - needed for path normalization
    try:
        git_root = get_git_root()
    except subprocess.CalledProcessError as e:
        print(f"Failed to get git root: {e}", file=sys.stderr)
        return 1

    if file_path:
        abs_path = os.path.abspath(file_path)
        # If the absolute path doesn't exist, check if path is relative to git root
        if not os.path.exists(abs_path):
            abs_from_root = os.path.join(git_root, file_path)
            if os.path.exists(abs_from_root):
                abs_path = os.path.abspath(abs_from_root)
        target_file = os.path.relpath(abs_path, git_root)
    else:
        try:
            all_files = get_all_changed_files()
        except subprocess.CalledProcessError as e:
            print(f"Failed to get changed files: {e}", file=sys.stderr)
            return 1

        if not all_files:
            print("No changed files", file=sys.stderr)
            return 1

        if len(all_files) != 1:
            print(
                f"Expected 1 changed file, found {len(all_files)}:",
                file=sys.stderr,
            )
            for f in all_files:
                print(f"  {f}", file=sys.stderr)
            return 1

        target_file = all_files[0]

    prefix = shorten_path(target_file)

    def _too_long(p: str) -> bool:
        return len(p) > MAX_PREFIX_LENGTH or len(create_commit_message(p, subject)) > MAX_MESSAGE_LENGTH

    # Apply aggressive directory shortening if scope or total message exceeds limit
    if _too_long(prefix):
        prefix = shorten_directories(prefix)

    if _too_long(prefix):
        prefix = collapse_middle(prefix)

    if _too_long(prefix):
        print(
            f"Scope too long: {len(prefix)} chars (max {MAX_PREFIX_LENGTH})",
            file=sys.stderr,
        )
        print(f"Scope: {prefix}", file=sys.stderr)
        return 1

    message = create_commit_message(prefix, subject)

    if len(message) > MAX_MESSAGE_LENGTH:
        print(
            f"Subject too long: {len(message)} chars (max {MAX_MESSAGE_LENGTH})",
            file=sys.stderr,
        )
        print(f"Subject: {message}", file=sys.stderr)
        return 1

    # Set env var so pre-commit hook skips the "use git-message" hint
    os.environ["GIT_MESSAGE_CLI"] = "1"

    try:
        # Add untracked files first (git commit <file> only works for tracked files)
        if is_untracked(target_file, git_root):
            result = subprocess.run(
                ["git", "add", target_file],
                capture_output=True,
                text=True,
                cwd=git_root,
            )
            if result.returncode != 0:
                # Fall back to force-add (needed when .gitignore ignores the file)
                print(f"  add -f {target_file}")
                subprocess.run(
                    ["git", "add", "-f", target_file], check=True, cwd=git_root
                )
            else:
                print(f"  add {target_file}")

        print(f"  commit {target_file}")
        cmd = ["git", "commit", target_file, "-m", message]
        if body:
            cmd.extend(["-m", body])
        subprocess.run(cmd, check=True, cwd=git_root)
    except subprocess.CalledProcessError as e:
        print(f"Git commit failed: {e}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
