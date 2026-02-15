#!/usr/bin/env python3
"""CLI for Apple Notes via osascript."""

import os
import subprocess
import sys
import tempfile

import click


def run_osascript(body):
    """Run an AppleScript wrapped in tell application "Notes"."""
    script = f'tell application "Notes"\n{body}\nend tell'
    result = subprocess.run(
        ["osascript", "-e", script],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        click.echo(f"Error: {result.stderr.strip()}", err=True)
        sys.exit(1)
    return result.stdout.strip()


def find_note(folder, name):
    """AppleScript snippet to find a note by name in a folder."""
    return f'''set matchedNotes to every note in folder "{folder}" whose name is "{name}"
    if (count of matchedNotes) is 0 then
        error "Note not found: {name}"
    end if'''


def set_note_body(folder, name, new_text):
    """Set a note's body from plain text."""
    html_body = "".join(f"<div>{line or '<br>'}</div>" for line in new_text.splitlines())
    run_osascript(f'''{find_note(folder, name)}
    set body of item 1 of matchedNotes to "{html_body.replace('"', '\\"')}"''')


@click.group()
def cli():
    """Apple Notes CLI."""


@cli.command()
def folders():
    """List all folders."""
    output = run_osascript("get name of every folder")
    for folder in output.split(", "):
        click.echo(folder)


@cli.command("list")
@click.argument("folder")
def list_notes(folder):
    """List notes in a folder."""
    output = run_osascript(f'''set noteList to every note in folder "{folder}"
    set output to ""
    repeat with n in noteList
        set output to output & name of n & linefeed
    end repeat
    return output''')
    if output:
        for line in output.splitlines():
            if line:
                click.echo(line)


@cli.command()
@click.argument("folder")
@click.argument("name")
def view(folder, name):
    """View a note's content as plain text."""
    output = run_osascript(f'''{find_note(folder, name)}
    return plaintext of item 1 of matchedNotes''')
    click.echo(output)


@cli.command("next")
@click.argument("folder")
def next_note(folder):
    """Show the first (most recently modified) note in a folder."""
    output = run_osascript(f'''set n to item 1 of (every note in folder "{folder}")
    set d to modification date of n
    return name of n & linefeed & d & linefeed & plaintext of n''')
    click.echo(output)


@cli.command()
@click.argument("folder")
@click.argument("name")
@click.option("-f", "--file", "filepath", help="Read content from file instead of $EDITOR.")
def edit(folder, name, filepath):
    """Edit a note in $EDITOR, from a file, or from stdin."""
    if filepath:
        with open(filepath) as f:
            new_text = f.read()
        set_note_body(folder, name, new_text)
        click.echo(f"Updated '{name}' from {filepath}")
        return

    if not sys.stdin.isatty():
        new_text = sys.stdin.read()
        set_note_body(folder, name, new_text)
        click.echo(f"Updated '{name}'")
        return

    plaintext = run_osascript(f'''{find_note(folder, name)}
    return plaintext of item 1 of matchedNotes''')

    editor = os.environ.get("EDITOR", "vi")
    with tempfile.NamedTemporaryFile(suffix=".txt", mode="w", delete=False) as f:
        f.write(plaintext)
        tmp = f.name

    try:
        subprocess.run([editor, tmp], check=True)
        with open(tmp) as f:
            new_text = f.read()
        if new_text == plaintext:
            click.echo("No changes.")
            return
        set_note_body(folder, name, new_text)
        click.echo(f"Updated '{name}'")
    finally:
        os.unlink(tmp)


@cli.command()
@click.argument("name")
@click.argument("source")
@click.argument("dest")
def move(name, source, dest):
    """Move a note to another folder."""
    run_osascript(f'''{find_note(source, name)}
    move item 1 of matchedNotes to folder "{dest}"''')
    click.echo(f"Moved '{name}' from '{source}' to '{dest}'")


if __name__ == "__main__":
    cli()
