#!/usr/bin/env python3
"""Unstage and restore file(s) to HEAD in a single command."""

import argparse
import subprocess
import sys


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Unstage and restore file(s) to HEAD (git restore --staged --worktree).",
    )
    parser.add_argument(
        "files",
        nargs="+",
        help="File(s) to unstage and restore",
    )

    args = parser.parse_args()

    result = subprocess.run(
        ["git", "restore", "--staged", "--worktree", "--", *args.files],
    )
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
