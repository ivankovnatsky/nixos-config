#!/usr/bin/env python3
"""
Git commit message helper that auto-generates commit prefixes from staged files.

Usage:
    git-message "commit subject"

Features:
- Requires exactly one staged file
- Strips .nix extension from file path
- Shortens machine names (e.g., Ivans-Mac-mini -> mini)
- Validates commit message length (max 72 chars)
- Runs git commit with formatted message
"""

import subprocess
import sys

MACHINE_MAPPINGS = {
    "Ivans-Mac-mini": "mini",
    "Ivans-MacBook-Air": "air",
    "Ivans-MacBook-Pro": "pro",
    "Lusha-Macbook-Ivan-Kovnatskyi": "work",
}

MAX_MESSAGE_LENGTH = 72


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

    if result.endswith(".nix"):
        result = result[:-4]

    for long_name, short_name in MACHINE_MAPPINGS.items():
        result = result.replace(long_name, short_name)

    return result


def create_commit_message(prefix: str, subject: str) -> str:
    return f"{prefix}: {subject}"


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: git-message <subject>", file=sys.stderr)
        print('Example: git-message "add new feature"', file=sys.stderr)
        return 1

    subject = sys.argv[1]

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
    message = create_commit_message(prefix, subject)

    if len(message) > MAX_MESSAGE_LENGTH:
        print(
            f"Commit message too long: {len(message)} chars (max {MAX_MESSAGE_LENGTH})",
            file=sys.stderr,
        )
        print(f"Message: {message}", file=sys.stderr)
        return 1

    try:
        subprocess.run(["git", "commit", "-m", message], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Git commit failed: {e}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
