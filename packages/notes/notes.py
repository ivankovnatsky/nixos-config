#!/usr/bin/env python3
"""CLI for Apple Notes via osascript."""

import glob
import html
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
        self._link_text_start = 0
        self._tag_stack = []
        self._ul_depth = 0

    def _heading_level(self, tag):
        if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
            return int(tag[1])
        return 0

    def handle_starttag(self, tag, attrs):
        self._tag_stack.append(tag)
        if tag == "ul":
            self._ul_depth += 1
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
        if tag == "img":
            self._current += "[image]"

    def handle_data(self, data):
        if not data.strip():
            if self._current and not self._current.endswith(" "):
                self._current += " "
            return
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
            indent = "  " * max(0, self._ul_depth - 1)
            self._current = f"{indent}- "

    def handle_endtag(self, tag):
        if tag == "ul":
            self._ul_depth = max(0, self._ul_depth - 1)
        if tag == "a" and self._href:
            if self._href not in self._current:
                self._current += f" ({self._href})"
            self._href = None
        if tag in ("div", "p") or self._heading_level(tag):
            if self._current or not self._lines or self._lines[-1] != "":
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
            indent = "  " * max(0, self._ul_depth - 1)
            self._current = f"{indent}- "

    def handle_endtag(self, tag):
        if tag == "ul":
            self._ul_depth = max(0, self._ul_depth - 1)
        if tag == "a" and self._href:
            link_text = self._current[self._link_text_start :]
            self._current = self._current[: self._link_text_start]
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
            if self._current or not self._lines or self._lines[-1] != "":
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


def set_note_body(folder, name, new_text, preserve_title=False):
    """Set a note's body from plain text.

    When preserve_title is True, the existing title (first HTML element) is kept
    and only the content after it is replaced.
    """
    html_content = "".join(
        f"<div>{html.escape(line) if line else '<br>'}</div>"
        for line in new_text.splitlines()
    )
    if preserve_title:
        import re
        existing_body = run_osascript(
            f"""{find_note()}
    return body of item 1 of matchedNotes""",
            args=[folder, name],
        )
        title_match = re.match(r"<(?:h[1-6]|div)>.*?</(?:h[1-6]|div)>", existing_body)
        if title_match:
            html_content = title_match.group(0) + "\n<div><br></div>\n" + html_content
    run_osascript(
        f"""{find_note()}
    set body of item 1 of matchedNotes to (item 3 of argv)""",
        args=[folder, name, html_content],
    )


@click.group()
def cli():
    """Apple Notes CLI."""


@cli.command()
def folders():
    """List all folders."""
    output = run_osascript("get name of every folder")
    for folder in output.split(", "):
        click.echo(folder)


@cli.command("new-folder")
@click.argument("name")
def new_folder(name):
    """Create a new folder."""
    run_osascript(
        "make new folder with properties {name:(item 1 of argv)}",
        args=[name],
    )
    click.echo(f"Created folder '{name}'")


LIST_NOTES_SCRIPT = """set noteList to every note in folder (item 1 of argv)
    set output to ""
    repeat with n in noteList
        set output to output & name of n & linefeed
    end repeat
    return output"""


def _print_notes(folder, prefix=""):
    """List notes in a folder, optionally prefixing each line."""
    output = run_osascript(LIST_NOTES_SCRIPT, args=[folder])
    if output:
        for line in output.splitlines():
            if line:
                click.echo(f"{prefix}{line}" if prefix else line)


@cli.command("list")
@click.argument("folder", default="")
@click.option("--all", "all_folders", is_flag=True, help="List notes in all folders.")
def list_notes(folder, all_folders):
    """List notes in a folder (or all folders with --all)."""
    if all_folders or not folder:
        folder_names = run_osascript("get name of every folder").split(", ")
        for fname in folder_names:
            _print_notes(fname, prefix=f"{fname}/")
    else:
        _print_notes(folder)


@cli.command()
@click.argument("folder")
@click.argument("name")
@click.option(
    "-f",
    "--format",
    "fmt",
    type=click.Choice(["text", "md", "html", "plain"]),
    default="text",
    help="Output format.",
)
@click.option(
    "--no-title", is_flag=True, default=False, help="Skip the first line (note title)."
)
def view(folder, name, fmt, no_title):
    """View a note's content."""
    if fmt == "plain":
        output = run_osascript(
            f"""{find_note()}
    return plaintext of item 1 of matchedNotes""",
            args=[folder, name],
        )
        if no_title:
            lines = output.split("\n", 1)
            output = lines[1].lstrip("\n") if len(lines) > 1 else ""
        click.echo(output)
    else:
        html_body = run_osascript(
            f"""{find_note()}
    return body of item 1 of matchedNotes""",
            args=[folder, name],
        )
        text = html_to_text(html_body, fmt)
        if no_title:
            lines = text.split("\n", 1)
            text = lines[1].lstrip("\n") if len(lines) > 1 else ""
        click.echo(text)


@cli.command("next")
@click.argument("folder")
@click.option(
    "-f",
    "--format",
    "fmt",
    type=click.Choice(["text", "md", "html", "plain"]),
    default="text",
    help="Output format.",
)
def next_note(folder, fmt):
    """Show the first (most recently modified) note in a folder."""
    output = run_osascript(
        """set n to item 1 of (every note in folder (item 1 of argv))
    return name of n & linefeed & modification date of n""",
        args=[folder],
    )
    parts = output.split("\n", 1)
    note_name = parts[0]
    click.echo(note_name)
    if len(parts) > 1:
        click.echo(parts[1])
    if fmt == "plain":
        body = run_osascript(
            f"""{find_note()}
    return plaintext of item 1 of matchedNotes""",
            args=[folder, note_name],
        )
        click.echo(body)
    else:
        html_body = run_osascript(
            f"""{find_note()}
    return body of item 1 of matchedNotes""",
            args=[folder, note_name],
        )
        click.echo(html_to_text(html_body, fmt))


@cli.command()
@click.argument("folder")
@click.argument("name")
@click.option(
    "-f", "--file", "filepath", help="Read content from file instead of $EDITOR."
)
def edit(folder, name, filepath):
    """Edit a note in $EDITOR, from a file, or from stdin."""
    if filepath:
        with open(filepath) as f:
            new_text = f.read()
        set_note_body(folder, name, new_text, preserve_title=True)
        click.echo(f"Updated '{name}' from {filepath}")
        return

    if not sys.stdin.isatty():
        new_text = sys.stdin.read()
        set_note_body(folder, name, new_text, preserve_title=True)
        click.echo(f"Updated '{name}'")
        return

    plaintext = run_osascript(
        f"""{find_note()}
    return plaintext of item 1 of matchedNotes""",
        args=[folder, name],
    )

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
@click.option(
    "-f",
    "--format",
    "fmt",
    type=click.Choice(["markdown"]),
    default="markdown",
    help="Export format.",
)
@click.option("-p", "--path", "export_path", help="Directory to export into.")
@click.option(
    "--clean",
    is_flag=True,
    default=False,
    help="Remove export directory after reading.",
)
def export(folder, name, fmt, export_path, clean):
    """Export a note using Apple Notes native export."""
    click.echo(export_markdown(folder, name, export_path=export_path, clean=clean))


@cli.command()
@click.argument("name")
@click.argument("source")
@click.argument("dest")
@click.option("-c", "--create", "create_folder", is_flag=True, help="Create destination folder if it doesn't exist.")
def move(name, source, dest, create_folder):
    """Move a note to another folder."""
    if create_folder:
        existing = run_osascript("get name of every folder").split(", ")
        if dest not in existing:
            run_osascript(
                "make new folder with properties {name:(item 1 of argv)}",
                args=[dest],
            )
    run_osascript(
        f"""{find_note()}
    move item 1 of matchedNotes to folder (item 3 of argv)""",
        args=[source, name, dest],
    )
    click.echo(f"Moved '{name}' from '{source}' to '{dest}'")


@cli.command()
@click.argument("folder")
@click.argument("body")
@click.option("-n", "--name", "title", default=None, help="Note title (default: first line of body).")
def create(folder, body, title):
    """Create a new note in a folder."""
    if title:
        html_body = f"<div><h1>{html.escape(title)}</h1></div>"
        html_body += "<div><br></div>"
        html_body += "".join(
            f"<div>{html.escape(line) if line else '<br>'}</div>"
            for line in body.splitlines()
        )
    else:
        lines = body.splitlines()
        title = lines[0] if lines else body
        body_lines = lines[1:] if len(lines) > 1 else []
        html_body = f"<div>{html.escape(title)}</div>"
        if body_lines:
            html_body += "<div><br></div>"
            html_body += "".join(
                f"<div>{html.escape(line) if line else '<br>'}</div>"
                for line in body_lines
            )
    run_osascript(
        """set newNote to make new note at folder (item 1 of argv) with properties {body:(item 2 of argv)}""",
        args=[folder, html_body],
    )
    click.echo(f"Created '{title}' in '{folder}'")


@cli.command()
@click.argument("folder")
@click.argument("name")
def delete(folder, name):
    """Delete a note."""
    click.confirm(f"Delete '{name}' from '{folder}'?", abort=True)
    run_osascript(
        f"""{find_note()}
    delete item 1 of matchedNotes""",
        args=[folder, name],
    )
    click.echo(f"Deleted '{name}' from '{folder}'")


@cli.command()
@click.argument("folder")
@click.argument("name")
@click.argument("new_name")
def rename(folder, name, new_name):
    """Rename a note by setting its name property directly."""
    run_osascript(
        f"""{find_note()}
    set name of item 1 of matchedNotes to (item 3 of argv)""",
        args=[folder, name, new_name],
    )
    click.echo(f"Renamed '{name}' -> '{new_name}'")


SEARCH_SCRIPT = """set matchedNotes to every note in folder (item 1 of argv) whose plaintext contains (item 2 of argv)
    set output to ""
    repeat with n in matchedNotes
        set output to output & name of n & linefeed
    end repeat
    return output"""


def _search_folder(fname, query):
    """Search notes in a folder and print matches."""
    output = run_osascript(SEARCH_SCRIPT, args=[fname, query])
    if output:
        for line in output.splitlines():
            if line:
                click.echo(f"{fname}/{line}")


@cli.command()
@click.argument("query")
@click.option("--folder", default=None, help="Limit search to a specific folder.")
def search(query, folder):
    """Search notes by content."""
    if folder:
        _search_folder(folder, query)
    else:
        folder_names = run_osascript("get name of every folder").split(", ")
        for fname in folder_names:
            _search_folder(fname, query)


if __name__ == "__main__":
    cli()
