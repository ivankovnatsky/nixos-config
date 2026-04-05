"""AppleScript helpers for interacting with Apple Notes."""

import html
import re
import subprocess
import sys

import click


def run_osascript(body, args=None):
    """Run an AppleScript wrapped in tell application "Notes".

    When args are provided, the script is wrapped in ``on run argv`` and
    user-provided strings are passed as osascript arguments instead of being
    embedded in AppleScript source.  This avoids escaping issues with Unicode
    characters that AppleScript treats as special syntax (guillemets, curly
    quotes, etc.).
    """
    if args:
        script = f'on run argv\ntell application "Notes"\n{body}\nend tell\nend run'
        cmd = ["osascript", "-e", script] + list(args)
    else:
        script = f'tell application "Notes"\n{body}\nend tell'
        cmd = ["osascript", "-e", script]
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        click.echo(f"Error: {result.stderr.strip()}", err=True)
        sys.exit(1)
    return result.stdout.strip()


def find_note():
    """AppleScript snippet to find a note by name in a folder.

    Expects folder as item 1 of argv and name as item 2 of argv.
    """
    return """set matchedNotes to every note in folder (item 1 of argv) whose name is (item 2 of argv)
    if (count of matchedNotes) is 0 then
        error "Note not found"
    end if"""


def _rename_note(folder, old_name, new_name):
    """Rename a note, updating both name property and body title.

    For notes with attachments, only the name property is updated
    (body replacement would strip them). Returns True if body title
    was also updated.
    """
    att_count = _get_attachment_count(folder, old_name)
    run_osascript(
        f"""{find_note()}
    set name of item 1 of matchedNotes to (item 3 of argv)""",
        args=[folder, old_name, new_name],
    )
    if att_count == 0:
        existing_body = run_osascript(
            f"""{find_note()}
    return body of item 1 of matchedNotes""",
            args=[folder, new_name],
        )
        title_match = re.match(
            r"(<(?:h[1-6]|div)>)(.*?)(</(?:h[1-6]|div)>)", existing_body, re.DOTALL
        )
        if title_match:
            # Ensure title uses <h1> (Apple Notes default for new notes)
            renamed_body = (
                "<div><h1>"
                + html.escape(new_name)
                + "</h1></div>"
                + existing_body[title_match.end() :]
            )
            run_osascript(
                f"""{find_note()}
    set body of item 1 of matchedNotes to (item 3 of argv)""",
                args=[folder, new_name, renamed_body],
            )
        return True
    click.echo(
        f"Note has {att_count} attachment(s): body title not updated to preserve them.",
        err=True,
    )
    return False


def _get_attachment_count(folder, name):
    """Return the number of attachments on a note."""
    output = run_osascript(
        f"""{find_note()}
    set n to item 1 of matchedNotes
    set attList to every attachment of n
    return (count of attList) as text""",
        args=[folder, name],
    )
    return int(output)
