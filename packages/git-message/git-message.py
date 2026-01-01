#!/usr/bin/env python3
"""
Git commit subject scope helper that auto-generates scope from staged file paths.
"""

import argparse
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


def get_staged_files() -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--staged", "--name-only"],
        capture_output=True,
        text=True,
        check=True,
    )
    files = [f for f in result.stdout.strip().split("\n") if f]
    return files


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


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Auto-generate git commit subject scope from staged file paths.",
        epilog="""
Examples:
  git-message "add feature"     Commits with "<scope>: add feature"
  git-message "fix bug"         Commits with "<scope>: fix bug"

Features:
  - Requires exactly one staged file
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
    parser.add_argument("subject", help="commit subject (without scope prefix)")
    args = parser.parse_args()

    try:
        staged_files = get_staged_files()
    except subprocess.CalledProcessError as e:
        print(f"Failed to get staged files: {e}", file=sys.stderr)
        return 1

    if not staged_files:
        print("No staged files", file=sys.stderr)
        return 1

    if len(staged_files) != 1:
        print(
            f"Expected 1 staged file, found {len(staged_files)}:", file=sys.stderr
        )
        for f in staged_files:
            print(f"  {f}", file=sys.stderr)
        return 1

    staged_file = staged_files[0]
    prefix = shorten_path(staged_file)

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

    message = create_commit_message(prefix, args.subject)

    if len(message) > MAX_MESSAGE_LENGTH:
        print(
            f"Subject too long: {len(message)} chars (max {MAX_MESSAGE_LENGTH})",
            file=sys.stderr,
        )
        print(f"Subject: {message}", file=sys.stderr)
        return 1

    try:
        subprocess.run(["git", "commit", "-m", message], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Git commit failed: {e}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
