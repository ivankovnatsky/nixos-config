#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path


DEFAULT_EXPORT_BASE = os.path.expanduser(
    "~/Library/Mobile Documents/com~apple~CloudDocs/Data/Music"
)

APPLESCRIPT_TEMPLATE = '''
on run argv
    set exportDir to item 1 of argv

    tell application "Music"
        activate
    end tell

    delay 2

    tell application "System Events"
        tell process "Music"
            set frontmost to true
            delay 0.5

            click menu item "Export Library\u2026" of menu 1 of menu item "Library" of menu 1 of menu bar item "File" of menu bar 1

            delay 2

            keystroke "g" using {command down, shift down}
            delay 1

            keystroke exportDir
            delay 1
            keystroke return
            delay 2

            keystroke return
        end tell
    end tell

    delay 3
end run
'''


def run_osascript(export_dir: str) -> int:
    result = subprocess.run(
        ["osascript", "-e", APPLESCRIPT_TEMPLATE, export_dir],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"osascript error: {result.stderr.strip()}", file=sys.stderr)
    return result.returncode


def main():
    parser = argparse.ArgumentParser(description="Export Apple Music library to XML")
    parser.add_argument(
        "--output-dir",
        default=os.environ.get("MUSIC_EXPORT_PATH", DEFAULT_EXPORT_BASE),
        help="Base output directory (default: iCloud/Data/Music)",
    )
    parser.add_argument(
        "--date-dir",
        default=datetime.now().strftime("%Y-%m"),
        help="Date subdirectory name (default: current month)",
    )
    args = parser.parse_args()

    export_dir = Path(args.output_dir) / args.date_dir
    export_file = export_dir / "Library.xml"

    if export_file.exists():
        print(f"Export already exists: {export_file}")
        return 0

    export_dir.mkdir(parents=True, exist_ok=True)

    print(f"Exporting Music library to: {export_file}")

    rc = run_osascript(str(export_dir))
    if rc != 0:
        return rc

    if export_file.exists():
        print(f"Export successful: {export_file}")
        return 0

    print(
        f"Warning: export file not found at {export_file}",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
