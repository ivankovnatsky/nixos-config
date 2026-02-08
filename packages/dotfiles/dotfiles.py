#!/usr/bin/env python3
"""Git dotfiles management tool.

Subcommands:
  init    Initialize git repo at ~/ with managed dotfiles
"""

import argparse
import subprocess
import sys
from pathlib import Path

HOME = Path.home()

MANAGED_FILES = {
    ".gitignore": "**\n",
}


def apply_files() -> None:
    for filename, content in MANAGED_FILES.items():
        path = HOME / filename
        path.write_text(content)
        print(f"Set {path}")


def cmd_init(args: argparse.Namespace) -> int:
    result = subprocess.run(
        ["git", "init"],
        cwd=HOME,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"Error: {result.stderr}", file=sys.stderr)
        return 1
    print(result.stdout.strip())

    apply_files()

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Git dotfiles management tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    init_parser = subparsers.add_parser(
        "init",
        help="Initialize git repo at ~/ with .gitignore ignoring all",
    )
    init_parser.set_defaults(func=cmd_init)

    subparsers.add_parser(
        "help",
        aliases=["h"],
        help="Show this help message",
    )

    args = parser.parse_args()

    if not args.command or args.command in ("help", "h"):
        parser.print_help()
        return 0

    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
