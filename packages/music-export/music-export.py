#!/usr/bin/env python3

import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import click


DEFAULT_EXPORT_BASE = os.path.expanduser(
    "~/Library/Mobile Documents/com~apple~CloudDocs/Data/Music"
)

APPLESCRIPT_TEMPLATE = """
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
"""


def run_osascript(export_dir: str) -> int:
    result = subprocess.run(
        ["osascript", "-e", APPLESCRIPT_TEMPLATE, export_dir],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        click.echo(f"osascript error: {result.stderr.strip()}", err=True)
    return result.returncode


@click.command()
@click.option(
    "--output-dir",
    default=os.environ.get("MUSIC_EXPORT_PATH", DEFAULT_EXPORT_BASE),
    help="Base output directory (default: iCloud/Data/Music)",
)
@click.option(
    "--date-dir",
    default=datetime.now().strftime("%Y-%m"),
    help="Date subdirectory name (default: current month)",
)
def main(output_dir, date_dir):
    """Export Apple Music library to XML."""
    export_dir = Path(output_dir) / date_dir
    export_file = export_dir / "Library.xml"

    if export_file.exists():
        click.echo(f"Export already exists: {export_file}")
        sys.exit(0)

    export_dir.mkdir(parents=True, exist_ok=True)

    click.echo(f"Exporting Music library to: {export_file}")

    rc = run_osascript(str(export_dir))
    if rc != 0:
        sys.exit(rc)

    if export_file.exists():
        click.echo(f"Export successful: {export_file}")
        sys.exit(0)

    click.echo(
        f"Warning: export file not found at {export_file}",
        err=True,
    )
    sys.exit(1)


if __name__ == "__main__":
    main(prog_name="music-export")
