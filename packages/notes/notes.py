#!/usr/bin/env python3
"""CLI for Apple Notes via osascript."""

import glob
import html.parser
import os
import shutil
import subprocess
import sys
import tempfile

import click


class BaseHTMLParser(html.parser.HTMLParser):
    """Base parser for Apple Notes HTML body."""

    def __init__(self):
        super().__init__()
        self._lines = []
        self._current = ""
        self._href = None
        self._tag_stack = []

    def _heading_level(self, tag):
        if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
            return int(tag[1])
        return 0

    def handle_starttag(self, tag, attrs):
        self._tag_stack.append(tag)
        if tag in ("div", "br", "p") or self._heading_level(tag):
            if self._current:
                self._lines.append(self._current)
                self._current = ""
        if tag == "a":
            for k, v in attrs:
                if k == "href":
                    self._href = v
                    self._link_text_start = len(self._current)
        if tag == "li":
            if self._current:
                self._lines.append(self._current)
                self._current = ""

    def handle_data(self, data):
        self._current += data

    def get_text(self):
        if self._current:
            self._lines.append(self._current)
        return "\n".join(self._lines)


class TextHTMLParser(BaseHTMLParser):
    """Convert HTML to plain text with links in parentheses."""

    def handle_starttag(self, tag, attrs):
        super().handle_starttag(tag, attrs)
        if tag == "li":
            self._current = "- "

    def handle_endtag(self, tag):
        if tag == "a" and self._href:
            if self._href not in self._current:
                self._current += f" ({self._href})"
            self._href = None
        if tag in ("div", "p") or self._heading_level(tag):
            self._lines.append(self._current)
            self._current = ""
        if tag in self._tag_stack:
            self._tag_stack.remove(tag)


class MarkdownHTMLParser(BaseHTMLParser):
    """Convert HTML to Markdown."""

    def handle_starttag(self, tag, attrs):
        super().handle_starttag(tag, attrs)
        level = self._heading_level(tag)
        if level:
            self._current = "#" * level + " "
        if tag == "b" or tag == "strong":
            self._current += "**"
        if tag == "i" or tag == "em":
            self._current += "*"
        if tag == "li":
            self._current = "- "

    def handle_endtag(self, tag):
        if tag == "a" and self._href:
            link_text = self._current[self._link_text_start:]
            self._current = self._current[:self._link_text_start]
            if link_text == self._href:
                self._current += self._href
            else:
                self._current += f"[{link_text}]({self._href})"
            self._href = None
        if tag == "b" or tag == "strong":
            self._current += "**"
        if tag == "i" or tag == "em":
            self._current += "*"
        if tag in ("div", "p") or self._heading_level(tag):
            self._lines.append(self._current)
            self._current = ""
        if tag in self._tag_stack:
            self._tag_stack.remove(tag)


def html_to_text(html_body, fmt="text"):
    """Convert HTML note body to the specified format."""
    if fmt == "html":
        return html_body
    if fmt == "plain":
        parser = BaseHTMLParser()
    elif fmt == "md":
        parser = MarkdownHTMLParser()
    else:
        parser = TextHTMLParser()
    parser.feed(html_body)
    return parser.get_text()


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


def export_markdown(folder, name, export_path=None, clean=False):
    """Export a note using Apple Notes native Markdown export."""
    tmpdir = export_path or "/tmp/notes-export"
    os.makedirs(tmpdir, exist_ok=True)
    script = f'''
tell application "Notes"
    {find_note(folder, name)}
    show item 1 of matchedNotes
end tell
delay 1
set the clipboard to "{tmpdir}"
tell application "System Events"
    tell process "Notes"
        click menu item "Markdown" of menu 1 of menu item "Export as" of menu 1 of menu bar item "File" of menu bar 1
        delay 1
        keystroke "g" using {{command down, shift down}}
        delay 1
        keystroke "v" using {{command down}}
        delay 0.5
        key code 36
        delay 1
        key code 36
    end tell
end tell
delay 2'''
    result = subprocess.run(
        ["osascript", "-e", script],
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
@click.option("-f", "--format", "fmt", type=click.Choice(["text", "md", "html", "plain"]), default="text", help="Output format.")
def view(folder, name, fmt):
    """View a note's content."""
    if fmt == "plain":
        output = run_osascript(f'''{find_note(folder, name)}
    return plaintext of item 1 of matchedNotes''')
        click.echo(output)
    else:
        html_body = run_osascript(f'''{find_note(folder, name)}
    return body of item 1 of matchedNotes''')
        click.echo(html_to_text(html_body, fmt))


@cli.command("next")
@click.argument("folder")
@click.option("-f", "--format", "fmt", type=click.Choice(["text", "md", "html", "plain"]), default="text", help="Output format.")
def next_note(folder, fmt):
    """Show the first (most recently modified) note in a folder."""
    output = run_osascript(f'''set n to item 1 of (every note in folder "{folder}")
    return name of n & linefeed & modification date of n''')
    parts = output.split("\n", 1)
    note_name = parts[0]
    click.echo(note_name)
    if len(parts) > 1:
        click.echo(parts[1])
    if fmt == "plain":
        body = run_osascript(f'''{find_note(folder, note_name)}
    return plaintext of item 1 of matchedNotes''')
        click.echo(body)
    else:
        html_body = run_osascript(f'''{find_note(folder, note_name)}
    return body of item 1 of matchedNotes''')
        click.echo(html_to_text(html_body, fmt))


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
@click.argument("folder")
@click.argument("name")
@click.option("-f", "--format", "fmt", type=click.Choice(["markdown"]), default="markdown", help="Export format.")
@click.option("-p", "--path", "export_path", help="Directory to export into.")
@click.option("--clean", is_flag=True, default=False, help="Remove export directory after reading.")
def export(folder, name, fmt, export_path, clean):
    """Export a note using Apple Notes native export."""
    click.echo(export_markdown(folder, name, export_path=export_path, clean=clean))


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
