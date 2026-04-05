"""Note body helpers for reading and writing note content."""

import glob
import html
import os
import re
import shutil
import subprocess
import sys

import click

from applescript import run_osascript, find_note
from cache import cache_invalidate


def export_markdown(folder, name, export_path=None, clean=False):
    """Export a note using Apple Notes native Markdown export."""
    tmpdir = export_path or "/tmp/notes-export"
    os.makedirs(tmpdir, exist_ok=True)
    script = f"""on run argv
tell application "Notes"
    {find_note()}
    show item 1 of matchedNotes
end tell
delay 2
set the clipboard to (item 3 of argv)
tell application "System Events"
    tell process "Notes"
        click menu item "Markdown" of menu 1 of menu item "Export as" of menu 1 of menu bar item "File" of menu bar 1
        delay 2
        keystroke "g" using {{command down, shift down}}
        delay 2
        keystroke "v" using {{command down}}
        delay 2
        key code 36
        delay 2
        key code 36
    end tell
end tell
delay 3
end run"""
    result = subprocess.run(
        ["osascript", "-e", script, folder, name, tmpdir],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        click.echo(f"Error: {result.stderr.strip()}", err=True)
        sys.exit(1)
    md_files = glob.glob(os.path.join(tmpdir, "**", "*.md"), recursive=True)
    if not md_files:
        click.echo("Error: export produced no markdown file", err=True)
        sys.exit(1)
    with open(md_files[0]) as f:
        content = f.read()
    if clean:
        shutil.rmtree(tmpdir, ignore_errors=True)
    return content


def _text_to_html_divs(text):
    """Convert plain text lines to Apple Notes HTML divs."""
    return "".join(
        f"<div>{html.escape(line) if line else '<br>'}</div>"
        for line in text.splitlines()
    )


def set_note_body(folder, name, new_text, preserve_title=False):
    """Set a note's body from plain text.

    When preserve_title is True, the existing title (first HTML element) is kept
    and only the content after it is replaced.
    """
    html_content = _text_to_html_divs(new_text)
    if preserve_title:
        existing_body = run_osascript(
            f"""{find_note()}
    return body of item 1 of matchedNotes""",
            args=[folder, name],
        )
        title_match = re.match(
            r"<(?:h[1-6]|div)>.*?</(?:h[1-6]|div)>", existing_body, re.DOTALL
        )
        if title_match:
            html_content = title_match.group(0) + "\n<div><br></div>\n" + html_content
    run_osascript(
        f"""{find_note()}
    set body of item 1 of matchedNotes to (item 3 of argv)""",
        args=[folder, name, html_content],
    )
    cache_invalidate()
