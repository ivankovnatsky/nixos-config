#!/usr/bin/env python3

"""
Git commit subject scope helper that auto-generates scope from staged file paths.
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
MAX_PREFIX_LENGTH = 40


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


def is_untracked(file_path: str, git_root: str) -> bool:
    """Check if a file is untracked by git."""
    result = subprocess.run(
        ["git", "ls-files", "--error-unmatch", file_path],
        capture_output=True,
        text=True,
        cwd=git_root,
    )
    return result.returncode != 0


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


def create_commit_message(prefix: str, subject: str) -> str:
    return f"{prefix}: {subject}"


def parse_args_flexible(
    args: list[str], subject_flag: str | None
) -> tuple[str | None, str]:
    """Parse arguments flexibly: file can be before or after subject."""
    if subject_flag:
        # Subject provided via -s flag
        if len(args) == 0:
            return None, subject_flag
        elif len(args) == 1:
            if os.path.exists(args[0]):
                return args[0], subject_flag
            else:
                print(f"Error: File not found: {args[0]}", file=sys.stderr)
                sys.exit(1)
        else:
            print("Error: Too many positional args with -s flag", file=sys.stderr)
            sys.exit(1)

    # Original behavior: subject from positional args
    if len(args) == 1:
        return None, args[0]
    elif len(args) == 2:
        # Check which argument is an existing file
        first_exists = os.path.exists(args[0])
        second_exists = os.path.exists(args[1])

        if first_exists and not second_exists:
            return args[0], args[1]
        elif second_exists and not first_exists:
            return args[1], args[0]
        elif first_exists and second_exists:
            print("Error: Both arguments are existing files", file=sys.stderr)
            sys.exit(1)
        else:
            print("Error: Neither argument is an existing file", file=sys.stderr)
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
        description="Auto-generate git commit subject scope from staged file paths.",
        epilog="""
Examples:
  git-message "add feature"                     Commits staged file with "<scope>: add feature"
  git-message file.nix "add feature"            Commits file.nix with "<scope>: add feature"
  git-message "add feature" -b "Body text"      Commits with subject and body
  git-message "add feature" -b "L1" -b "L2"     Multiple -b joined with newline
  git-message -s "add feature" -b "Line 1
  Line 2"                                       Multiline body with newlines

Features:
  - Accepts file path in either position (auto-detected by existence)
  - Auto-adds untracked files before committing
  - Without file arg, uses exactly one staged file, or one modified file if none staged
  - Strips file extensions (e.g., .nix, .py)
  - Shortens machine names (e.g., Ivans-Mac-mini -> mini)
  - Removes duplicate path components (e.g., pkg/foo/foo -> pkg/foo)
  - Strips "default" filename (e.g., mod/foo/default -> mod/foo)
  - Shortens directories if scope > 40 (packages->pkg, modules->mod, etc.)
  - Validates scope length (max 40 chars)
  - Validates subject length (max 72 chars)
""",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "args", nargs="*", help="subject and optional file path (in any order)"
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
        # Use provided file path, convert to relative path from git root
        abs_path = os.path.abspath(file_path)
        target_file = os.path.relpath(abs_path, git_root)
        auto_stage = False
    else:
        # Check staged files first, then modified files
        try:
            staged_files = get_staged_files()
        except subprocess.CalledProcessError as e:
            print(f"Failed to get staged files: {e}", file=sys.stderr)
            return 1

        auto_stage = False
        if staged_files:
            if len(staged_files) != 1:
                print(
                    f"Expected 1 staged file, found {len(staged_files)}:",
                    file=sys.stderr,
                )
                for f in staged_files:
                    print(f"  {f}", file=sys.stderr)
                return 1
            target_file = staged_files[0]
        else:
            # No staged files, check for modified (unstaged) files
            try:
                modified_files = get_modified_files()
            except subprocess.CalledProcessError as e:
                print(f"Failed to get modified files: {e}", file=sys.stderr)
                return 1

            if not modified_files:
                print("No staged or modified files", file=sys.stderr)
                return 1

            if len(modified_files) != 1:
                print(
                    f"Expected 1 modified file, found {len(modified_files)}:",
                    file=sys.stderr,
                )
                for f in modified_files:
                    print(f"  {f}", file=sys.stderr)
                return 1

            target_file = modified_files[0]
            auto_stage = True

    prefix = shorten_path(target_file)

    # Apply aggressive directory shortening only if scope exceeds limit
    if len(prefix) > MAX_PREFIX_LENGTH:
        prefix = shorten_directories(prefix)

    if len(prefix) > MAX_PREFIX_LENGTH:
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

    try:
        # Add untracked files first (git commit <file> only works for tracked files)
        if file_path and is_untracked(target_file, git_root):
            subprocess.run(["git", "add", target_file], check=True, cwd=git_root)

        if file_path:
            # Commit specific file (stages and commits in one step)
            # target_file is already relative to git root from earlier conversion
            cmd = ["git", "commit", target_file, "-m", message]
        elif auto_stage:
            # Auto-stage and commit the single modified file
            # target_file is already relative to git root from git diff output
            cmd = ["git", "commit", target_file, "-m", message]
        else:
            # Commit staged files
            cmd = ["git", "commit", "-m", message]
        if body:
            cmd.extend(["-m", body])
        subprocess.run(cmd, check=True, cwd=git_root)
    except subprocess.CalledProcessError as e:
        print(f"Git commit failed: {e}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
