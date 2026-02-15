#!/usr/bin/env python3
"""CLI for Apple Notes via osascript."""

import argparse
import subprocess
import sys


def run_osascript(body):
    """Run an AppleScript wrapped in tell application "Notes"."""
    script = f'tell application "Notes"\n{body}\nend tell'
    result = subprocess.run(
        ["osascript", "-e", script],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"Error: {result.stderr.strip()}", file=sys.stderr)
        sys.exit(1)
    return result.stdout.strip()


def find_note(folder, name):
    """AppleScript snippet to find a note by name in a folder."""
    return f'''set matchedNotes to every note in folder "{folder}" whose name is "{name}"
    if (count of matchedNotes) is 0 then
        error "Note not found: {name}"
    end if'''


def list_folders():
    """List all folders in Apple Notes."""
    output = run_osascript("get name of every folder")
    for folder in output.split(", "):
        print(folder)


def list_notes(args):
    """List notes in a folder, sorted by modification date (newest first)."""
    output = run_osascript(f'''set noteList to every note in folder "{args.folder}"
    set output to ""
    repeat with n in noteList
        set output to output & name of n & linefeed
    end repeat
    return output''')
    if output:
        for line in output.splitlines():
            if line:
                print(line)


def view_note(args):
    """View a note's content as plain text."""
    output = run_osascript(f'''{find_note(args.folder, args.name)}
    return plaintext of item 1 of matchedNotes''')
    print(output)


def next_note(args):
    """Show the first (most recently modified) note in a folder."""
    output = run_osascript(f'''set n to item 1 of (every note in folder "{args.folder}")
    set d to modification date of n
    return name of n & linefeed & d & linefeed & plaintext of n''')
    print(output)


def move_note(args):
    """Move a note from one folder to another."""
    run_osascript(f'''{find_note(args.source, args.name)}
    move item 1 of matchedNotes to folder "{args.dest}"''')
    print(f"Moved '{args.name}' from '{args.source}' to '{args.dest}'")


def main():
    parser = argparse.ArgumentParser(description="Apple Notes CLI")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("folders", help="List all folders")

    list_parser = subparsers.add_parser("list", help="List notes in a folder")
    list_parser.add_argument("folder", help="Folder name")
    list_parser.set_defaults(func=list_notes)

    view_parser = subparsers.add_parser("view", help="View a note")
    view_parser.add_argument("folder", help="Folder name")
    view_parser.add_argument("name", help="Note name")
    view_parser.set_defaults(func=view_note)

    next_parser = subparsers.add_parser("next", help="Show first note in a folder")
    next_parser.add_argument("folder", help="Folder name")
    next_parser.set_defaults(func=next_note)

    move_parser = subparsers.add_parser("move", help="Move a note to another folder")
    move_parser.add_argument("name", help="Note name")
    move_parser.add_argument("source", help="Source folder name")
    move_parser.add_argument("dest", help="Destination folder name")
    move_parser.set_defaults(func=move_note)

    args = parser.parse_args()

    if args.command == "folders":
        list_folders()
    else:
        args.func(args)


if __name__ == "__main__":
    main()
