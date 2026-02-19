#!/usr/bin/env python3

"""Clean regenerable build artifacts from home directory to reclaim disk space.

Companion to backup-home: while backup-home excludes patterns from archives,
this tool actually removes them from disk.

Targets:
  - .venv/        Python virtual environments
  - node_modules/ Node.js dependencies

Dry-run by default. Use --delete to actually remove files.

2026-02-19: Initial implementation with .venv and node_modules.
"""

import argparse
import os
import shutil
import sys
from dataclasses import dataclass, field
from pathlib import Path

TARGET_DIRS = [".venv", "node_modules"]

SKIP_DIRS = {".git", ".Trash", "Library"}


@dataclass
class Finding:
    path: Path
    size: int
    count: int


@dataclass
class TargetResult:
    name: str
    findings: list[Finding] = field(default_factory=list)

    @property
    def total_size(self) -> int:
        return sum(f.size for f in self.findings)

    @property
    def total_count(self) -> int:
        return sum(f.count for f in self.findings)


def format_size(size_bytes: int) -> str:
    for unit in ("B", "K", "M", "G", "T"):
        if abs(size_bytes) < 1024:
            if unit == "B":
                return f"{size_bytes}{unit}"
            return f"{size_bytes:.1f}{unit}"
        size_bytes /= 1024
    return f"{size_bytes:.1f}P"


def dir_size(path: Path) -> tuple[int, int]:
    """Return (total_bytes, file_count) for a directory tree."""
    total = 0
    count = 0
    try:
        with os.scandir(path) as entries:
            for entry in entries:
                try:
                    if entry.is_file(follow_symlinks=False):
                        total += entry.stat(follow_symlinks=False).st_size
                        count += 1
                    elif entry.is_dir(follow_symlinks=False):
                        sub_total, sub_count = dir_size(Path(entry.path))
                        total += sub_total
                        count += sub_count
                except (PermissionError, OSError):
                    pass
    except (PermissionError, OSError):
        pass
    return total, count


def scan(home: Path) -> list[TargetResult]:
    results = {name: TargetResult(name=name) for name in TARGET_DIRS}

    for root, dirs, _ in os.walk(home, followlinks=False):
        for target_name in TARGET_DIRS:
            if target_name in dirs:
                target_path = Path(root) / target_name
                size, count = dir_size(target_path)
                results[target_name].findings.append(
                    Finding(path=target_path, size=size, count=count)
                )
                dirs.remove(target_name)

        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]

    return list(results.values())


def print_report(results: list[TargetResult], home: Path) -> int:
    grand_total = 0

    for result in results:
        if not result.findings:
            continue

        grand_total += result.total_size
        print(
            f"\n{result.name}/ — {format_size(result.total_size)}"
            f"  ({result.total_count} files, {len(result.findings)} dirs)"
        )

        top = sorted(result.findings, key=lambda f: f.size, reverse=True)[:5]
        for finding in top:
            rel = finding.path.relative_to(home)
            print(f"  {rel}  ({format_size(finding.size)})")
        if len(result.findings) > 5:
            print(f"  ... and {len(result.findings) - 5} more")

    print()
    print(f"Total reclaimable: {format_size(grand_total)}")

    return grand_total


def delete_targets(results: list[TargetResult]) -> tuple[int, int]:
    deleted = 0
    errors = 0

    for result in results:
        for finding in result.findings:
            try:
                shutil.rmtree(finding.path)
                deleted += finding.size
                print(f"  Removed: {finding.path}")
            except (PermissionError, OSError) as e:
                errors += 1
                print(f"  Error removing {finding.path}: {e}", file=sys.stderr)

    return deleted, errors


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="cleanup-home",
        description="Clean regenerable build artifacts from home directory.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
WARNING: This tool is beta and not fully tested. Review dry-run output
carefully before using --delete.

Safety:
  Dry-run by default. Use --delete to actually remove files.
  Only targets known-regenerable directories (.venv, node_modules).

Examples:
  cleanup-home                 # Scan and show what can be cleaned
  cleanup-home --delete        # Actually delete artifacts
""",
    )
    parser.add_argument(
        "--delete",
        action="store_true",
        help="Actually delete files (default is dry-run)",
    )

    args = parser.parse_args()
    home = Path.home()

    print(f"Scanning {home} ...")
    results = scan(home)

    grand_total = print_report(results, home)

    if grand_total == 0:
        print("Nothing to clean.")
        return 0

    if not args.delete:
        print("\nDry-run mode. Use --delete to remove.")
        return 0

    print("\nDeleting...")
    deleted, errors = delete_targets(results)
    print(f"\nDeleted: {format_size(deleted)}")
    if errors:
        print(f"Errors: {errors}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
