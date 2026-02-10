#!/usr/bin/env python3
"""Clean Syncthing conflict and temp files from directories."""

import argparse
import os
import re
import sys
from datetime import datetime
from pathlib import Path


MAX_FILES = 10

CONFLICT_PATTERN = re.compile(r"\.sync-conflict-")
TEMP_PATTERN = re.compile(r"^\.syncthing\..*\.tmp$")


def find_syncthing_files(directory: Path) -> list[Path]:
    """Find all Syncthing conflict and temp files in directory."""
    files = []
    for root, _, filenames in os.walk(directory):
        for filename in filenames:
            if CONFLICT_PATTERN.search(filename) or TEMP_PATTERN.match(filename):
                files.append(Path(root) / filename)
    return files


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Clean Syncthing conflict and temp files from directories.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""
Safety:
  - Dry-run by default (shows files without deleting)
  - Aborts if more than {MAX_FILES} files found (prevents bad pattern damage)
  - Matches: .sync-conflict-* and .syncthing.*.tmp files
""",
    )
    parser.add_argument(
        "--delete",
        action="store_true",
        help="Actually delete files (default is dry-run)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Bypass MAX_FILES limit (use with caution)",
    )
    parser.add_argument(
        "dirs",
        nargs="*",
        default=["."],
        metavar="DIRS",
        help="Directories to clean (default: current directory)",
    )

    args = parser.parse_args()

    for dir_path in args.dirs:
        directory = Path(dir_path)

        if not directory.is_dir():
            print(f"Skipping (not found): {dir_path}")
            continue

        files = find_syncthing_files(directory)
        count = len(files)

        if count == 0:
            print(f"No Syncthing files found in: {dir_path}")
            continue

        if count > MAX_FILES and not args.force:
            print(
                f"ERROR: Too many files ({count} > {MAX_FILES}) in {dir_path}. "
                "Use --force to override."
            )
            return 1

        print(f"Found {count} file(s) in: {dir_path}")
        for f in files:
            print(f"  {f}")

        if args.delete:
            print("Removing...")
            for f in files:
                print(f"  removed '{f}'")
                f.unlink()
        else:
            print("Dry-run mode. Use --delete to remove.")

    print(f"Syncthing cleanup complete at {datetime.now()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
