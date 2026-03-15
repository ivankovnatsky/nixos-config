#!/usr/bin/env python3
"""CLI for Apple Notes via osascript."""

import glob
import hashlib
import html
import html.parser
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

import click


# ---------------------------------------------------------------------------
# HTML parsing
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# Cache
# ---------------------------------------------------------------------------

CACHE_DIR = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "notes-cli")
CACHE_TTL = 300  # 5 minutes


def _cache_path(key):
    safe = hashlib.md5(key.encode()).hexdigest()
    return os.path.join(CACHE_DIR, f"{safe}.json")


def cache_get(key):
    """Return cached value or None if expired/missing."""
    path = _cache_path(key)
    try:
        with open(path) as f:
            data = json.load(f)
        if time.time() - data["ts"] < CACHE_TTL:
            return data["val"]
    except (OSError, json.JSONDecodeError, KeyError):
        pass
    return None


def cache_set(key, val):
    """Store value in cache."""
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(_cache_path(key), "w") as f:
        json.dump({"ts": time.time(), "val": val}, f)


def cache_invalidate():
    """Clear all cached data."""
    if os.path.isdir(CACHE_DIR):
        shutil.rmtree(CACHE_DIR, ignore_errors=True)


# ---------------------------------------------------------------------------
# AppleScript helpers
# ---------------------------------------------------------------------------

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
                "<div><h1>" + html.escape(new_name) + "</h1></div>"
                + existing_body[title_match.end():]
            )
            run_osascript(
                f"""{find_note()}
    set body of item 1 of matchedNotes to (item 3 of argv)""",
                args=[folder, new_name, renamed_body],
            )
        return True
    click.echo(
        f"Note has {att_count} attachment(s): "
        "body title not updated to preserve them.",
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


# ---------------------------------------------------------------------------
# Note body helpers
# ---------------------------------------------------------------------------

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
        title_match = re.match(r"<(?:h[1-6]|div)>.*?</(?:h[1-6]|div)>", existing_body, re.DOTALL)
        if title_match:
            html_content = title_match.group(0) + "\n<div><br></div>\n" + html_content
    run_osascript(
        f"""{find_note()}
    set body of item 1 of matchedNotes to (item 3 of argv)""",
        args=[folder, name, html_content],
    )
    cache_invalidate()



# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

@click.group()
def cli():
    """Apple Notes CLI."""


# -- folders ----------------------------------------------------------------

@cli.command()
@click.option("--json", "as_json", is_flag=True, help="Output as JSON.")
def folders(as_json):
    """List all folders."""
    cached = cache_get("folders")
    if cached:
        names = cached
    else:
        output = run_osascript("get name of every folder")
        names = output.split(", ")
        cache_set("folders", names)
    if as_json:
        click.echo(json.dumps(names, indent=2))
    else:
        for folder in names:
            click.echo(folder)


@cli.command("new-folder")
@click.argument("name")
def new_folder(name):
    """Create a new folder."""
    run_osascript(
        "make new folder with properties {name:(item 1 of argv)}",
        args=[name],
    )
    cache_invalidate()
    click.echo(f"Created folder '{name}'")


@cli.command("delete-folder")
@click.argument("name")
def delete_folder(name):
    """Delete all notes in a folder.

    Apple Notes does not allow folder deletion via AppleScript,
    so this deletes all notes inside the folder (moving them to
    Recently Deleted). The empty folder must be removed manually.
    """
    click.confirm(f"Delete all notes in folder '{name}'?", abort=True)
    run_osascript(
        """set targetFolder to folder (item 1 of argv)
    repeat with n in (every note in targetFolder)
        delete n
    end repeat""",
        args=[name],
    )
    cache_invalidate()
    click.echo(f"Deleted all notes in '{name}' (empty folder remains)")


# -- list / count -----------------------------------------------------------

LIST_NOTES_SCRIPT = """set noteList to every note in folder (item 1 of argv)
    set output to ""
    repeat with n in noteList
        set output to output & name of n & linefeed
    end repeat
    return output"""

LIST_NOTES_DETAIL_SCRIPT = """set noteList to every note in folder (item 1 of argv)
    set output to ""
    repeat with n in noteList
        set aCount to count of every attachment of n
        set output to output & name of n & "<<F>>" & (modification date of n as text) & "<<F>>" & (aCount as text) & linefeed
    end repeat
    return output"""

COUNT_SCRIPT = """return (count of every note in folder (item 1 of argv)) as text"""


def _get_folder_names():
    cached = cache_get("folders")
    if cached:
        return cached
    output = run_osascript("get name of every folder")
    names = output.split(", ")
    cache_set("folders", names)
    return names


def _print_notes(folder, prefix="", detailed=False):
    """List notes in a folder, optionally prefixing each line."""
    if detailed:
        output = run_osascript(LIST_NOTES_DETAIL_SCRIPT, args=[folder])
        if output:
            for line in output.splitlines():
                if not line:
                    continue
                parts = line.split("<<F>>")
                name = parts[0]
                mod_date = parts[1] if len(parts) > 1 else ""
                att_count = parts[2] if len(parts) > 2 else "0"
                display = f"{prefix}{name}"
                meta = []
                if mod_date:
                    meta.append(mod_date.strip())
                if int(att_count) > 0:
                    meta.append(f"{att_count} attachment{'s' if int(att_count) != 1 else ''}")
                if meta:
                    display += f"  [{', '.join(meta)}]"
                click.echo(display)
    else:
        output = run_osascript(LIST_NOTES_SCRIPT, args=[folder])
        if output:
            for line in output.splitlines():
                if line:
                    click.echo(f"{prefix}{line}" if prefix else line)


@cli.command("list")
@click.argument("folder", default="")
@click.option("--all", "all_folders", is_flag=True, help="List notes in all folders.")
@click.option("--json", "as_json", is_flag=True, help="Output as JSON.")
@click.option("-l", "--long", "detailed", is_flag=True, help="Show modification date and attachment count.")
@click.option("--no-cache", is_flag=True, help="Bypass cache.")
def list_notes(folder, all_folders, as_json, detailed, no_cache):
    """List notes in a folder (or all folders with --all)."""
    if no_cache:
        cache_invalidate()
    if as_json:
        result = {}
        if all_folders or not folder:
            folder_names = _get_folder_names()
        else:
            folder_names = [folder]
        for fname in folder_names:
            output = run_osascript(LIST_NOTES_DETAIL_SCRIPT, args=[fname])
            notes = []
            if output:
                for line in output.splitlines():
                    if not line:
                        continue
                    parts = line.split("<<F>>")
                    notes.append({
                        "name": parts[0],
                        "modified": parts[1].strip() if len(parts) > 1 else "",
                        "attachments": int(parts[2]) if len(parts) > 2 else 0,
                    })
            result[fname] = notes
        click.echo(json.dumps(result, indent=2))
        return

    if all_folders or not folder:
        folder_names = _get_folder_names()
        for fname in folder_names:
            _print_notes(fname, prefix=f"{fname}/", detailed=detailed)
    else:
        _print_notes(folder, detailed=detailed)


@cli.command()
@click.argument("folder", default="")
@click.option("--all", "all_folders", is_flag=True, help="Count in all folders.")
@click.option("--json", "as_json", is_flag=True, help="Output as JSON.")
def count(folder, all_folders, as_json):
    """Count notes in a folder (or all folders with --all)."""
    if all_folders or not folder:
        folder_names = _get_folder_names()
        counts = {}
        total = 0
        for fname in folder_names:
            c = int(run_osascript(COUNT_SCRIPT, args=[fname]))
            counts[fname] = c
            total += c
        if as_json:
            counts["_total"] = total
            click.echo(json.dumps(counts, indent=2))
        else:
            for fname, c in counts.items():
                click.echo(f"{fname}: {c}")
            click.echo(f"Total: {total}")
    else:
        c = int(run_osascript(COUNT_SCRIPT, args=[folder]))
        if as_json:
            click.echo(json.dumps({"folder": folder, "count": c}))
        else:
            click.echo(c)


# -- view / info / next -----------------------------------------------------

@cli.command()
@click.argument("folder")
@click.argument("name")
@click.option(
    "-f", "--format", "fmt",
    type=click.Choice(["text", "md", "html", "plain"]),
    default="text",
    help="Output format.",
)
@click.option("--no-title", is_flag=True, default=False, help="Skip the first line (note title).")
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


@cli.command()
@click.argument("folder")
@click.argument("name")
@click.option("--json", "as_json", is_flag=True, help="Output as JSON.")
def info(folder, name, as_json):
    """Show metadata for a note (dates, folder, attachment count)."""
    output = run_osascript(
        f"""{find_note()}
    set n to item 1 of matchedNotes
    set aCount to count of every attachment of n
    return name of n & "<<F>>" & (id of n as text) & "<<F>>" & (creation date of n as text) & "<<F>>" & (modification date of n as text) & "<<F>>" & (aCount as text)""",
        args=[folder, name],
    )
    parts = output.split("<<F>>")
    data = {
        "name": parts[0],
        "id": parts[1] if len(parts) > 1 else "",
        "created": parts[2].strip() if len(parts) > 2 else "",
        "modified": parts[3].strip() if len(parts) > 3 else "",
        "attachments": int(parts[4]) if len(parts) > 4 else 0,
        "folder": folder,
    }
    if as_json:
        click.echo(json.dumps(data, indent=2))
    else:
        click.echo(f"Name:        {data['name']}")
        click.echo(f"Folder:      {data['folder']}")
        click.echo(f"Created:     {data['created']}")
        click.echo(f"Modified:    {data['modified']}")
        click.echo(f"Attachments: {data['attachments']}")
        click.echo(f"ID:          {data['id']}")


@cli.command("next")
@click.argument("folder")
@click.option(
    "-f", "--format", "fmt",
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


# -- edit -------------------------------------------------------------------

@cli.command()
@click.argument("folder")
@click.argument("name")
@click.option("-f", "--file", "filepath", help="Read content from file instead of $EDITOR.")
@click.option("--force", is_flag=True, help="Allow editing notes with attachments (may lose them).")
def edit(folder, name, filepath, force):
    """Edit a note in $EDITOR, from a file, or from stdin.

    Notes with attachments are protected by default. Editing a note via
    AppleScript replaces the body HTML, which strips embedded images and
    files. Use --force to override this safety check.
    """
    att_count = _get_attachment_count(folder, name) if not force else 0
    if att_count > 0:
        click.echo(
            f"Error: '{name}' has {att_count} attachment(s). "
            "Editing would remove them.\n"
            "Use --force to edit anyway, or use 'append'/'prepend' to add text safely.",
            err=True,
        )
        sys.exit(1)

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

    original_hash = hashlib.md5(plaintext.encode()).hexdigest()

    try:
        subprocess.run([editor, tmp], check=True)
        with open(tmp) as f:
            new_text = f.read()
        new_hash = hashlib.md5(new_text.encode()).hexdigest()
        if new_hash == original_hash:
            click.echo("No changes.")
            return
        set_note_body(folder, name, new_text)
        click.echo(f"Updated '{name}'")
    finally:
        os.unlink(tmp)


# -- append / prepend -------------------------------------------------------

@cli.command()
@click.argument("folder")
@click.argument("name")
@click.argument("text", default="")
@click.option("-f", "--file", "filepath", help="Read content from file.")
def append(folder, name, text, filepath):
    """Append text to a note without replacing existing content.

    Safe for notes with attachments -- only adds content at the end.
    Reads from argument, file, or stdin.
    """
    if filepath:
        with open(filepath) as f:
            text = f.read()
    elif not text and not sys.stdin.isatty():
        text = sys.stdin.read()

    if not text:
        click.echo("Error: no text provided.", err=True)
        sys.exit(1)

    html_addition = _text_to_html_divs(text)
    # Insert before closing </body> or append to body
    existing_body = run_osascript(
        f"""{find_note()}
    return body of item 1 of matchedNotes""",
        args=[folder, name],
    )
    # Add a blank line separator then the new content
    new_body = existing_body + "\n<div><br></div>\n" + html_addition
    run_osascript(
        f"""{find_note()}
    set body of item 1 of matchedNotes to (item 3 of argv)""",
        args=[folder, name, new_body],
    )
    cache_invalidate()
    click.echo(f"Appended to '{name}'")


@cli.command()
@click.argument("folder")
@click.argument("name")
@click.argument("text", default="")
@click.option("-f", "--file", "filepath", help="Read content from file.")
def prepend(folder, name, text, filepath):
    """Prepend text after the title without replacing existing content.

    Safe for notes with attachments -- only adds content after the title.
    Reads from argument, file, or stdin.
    """
    if filepath:
        with open(filepath) as f:
            text = f.read()
    elif not text and not sys.stdin.isatty():
        text = sys.stdin.read()

    if not text:
        click.echo("Error: no text provided.", err=True)
        sys.exit(1)

    html_addition = _text_to_html_divs(text)
    existing_body = run_osascript(
        f"""{find_note()}
    return body of item 1 of matchedNotes""",
        args=[folder, name],
    )
    # Insert after the title element
    title_match = re.match(r"<(?:h[1-6]|div)>.*?</(?:h[1-6]|div)>", existing_body, re.DOTALL)
    if title_match:
        rest = existing_body[title_match.end():]
        new_body = title_match.group(0) + "\n<div><br></div>\n" + html_addition + "\n<div><br></div>\n" + rest.lstrip("\n")
    else:
        new_body = html_addition + "\n<div><br></div>\n" + existing_body

    run_osascript(
        f"""{find_note()}
    set body of item 1 of matchedNotes to (item 3 of argv)""",
        args=[folder, name, new_body],
    )
    cache_invalidate()
    click.echo(f"Prepended to '{name}'")


# -- export -----------------------------------------------------------------

@cli.command()
@click.argument("folder")
@click.argument("name")
@click.option(
    "-f", "--format", "fmt",
    type=click.Choice(["markdown"]),
    default="markdown",
    help="Export format.",
)
@click.option("-p", "--path", "export_path", help="Directory to export into.")
@click.option("--clean", is_flag=True, default=False, help="Remove export directory after reading.")
def export(folder, name, fmt, export_path, clean):
    """Export a note using Apple Notes native export."""
    click.echo(export_markdown(folder, name, export_path=export_path, clean=clean))


# -- move / create / delete / rename ----------------------------------------

@cli.command()
@click.argument("name")
@click.argument("source")
@click.argument("dest")
@click.option("-c", "--create", "create_folder", is_flag=True, help="Create destination folder if it doesn't exist.")
def move(name, source, dest, create_folder):
    """Move a note to another folder."""
    if create_folder:
        existing = _get_folder_names()
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
    cache_invalidate()
    click.echo(f"Moved '{name}' from '{source}' to '{dest}'")


@cli.command()
@click.argument("folder")
@click.argument("body", default="")
@click.option("-n", "--name", "title", default=None, help="Note title (default: first line of body).")
@click.option("-f", "--file", "filepath", help="Read body from file.")
@click.option("--stdin", "from_stdin", is_flag=True, help="Read body from stdin.")
def create(folder, body, title, filepath, from_stdin):
    """Create a new note in a folder."""
    if filepath:
        with open(filepath) as f:
            body = f.read()
    elif from_stdin or (not body and not sys.stdin.isatty()):
        body = sys.stdin.read()

    if not body and not title:
        click.echo("Error: provide body text, --name, --file, or --stdin.", err=True)
        sys.exit(1)

    if title:
        html_body = f"<div><h1>{html.escape(title)}</h1></div>"
        if body:
            html_body += "<div><br></div>"
            html_body += _text_to_html_divs(body)
    else:
        lines = body.splitlines()
        title = lines[0] if lines else body
        body_lines = lines[1:] if len(lines) > 1 else []
        html_body = f"<div><h1>{html.escape(title)}</h1></div>"
        if body_lines:
            html_body += "<div><br></div>"
            html_body += _text_to_html_divs("\n".join(body_lines))

    run_osascript(
        """set newNote to make new note at folder (item 1 of argv) with properties {body:(item 2 of argv)}""",
        args=[folder, html_body],
    )
    cache_invalidate()
    click.echo(f"Created '{title}' in '{folder}'")


@cli.command()
@click.argument("folder")
@click.argument("name")
@click.option("--force", is_flag=True, help="Skip confirmation prompt.")
def delete(folder, name, force):
    """Delete a note."""
    if not force:
        click.confirm(f"Delete '{name}' from '{folder}'?", abort=True)
    run_osascript(
        f"""{find_note()}
    delete item 1 of matchedNotes""",
        args=[folder, name],
    )
    cache_invalidate()
    click.echo(f"Deleted '{name}' from '{folder}'")


@cli.command()
@click.argument("folder")
@click.argument("name")
@click.argument("new_name")
def rename(folder, name, new_name):
    """Rename a note (name property and body title).

    For notes without attachments, both the name property and the body
    title (first HTML element) are updated. For notes with attachments,
    only the name property is changed to avoid stripping attachments
    via body replacement.
    """
    _rename_note(folder, name, new_name)
    cache_invalidate()
    click.echo(f"Renamed '{name}' -> '{new_name}'")


@cli.command()
@click.argument("folder")
@click.argument("name")
@click.option("-n", "--new-name", default=None, help="Rename the duplicate after creation.")
def duplicate(folder, name, new_name):
    """Duplicate a note via the Notes.app UI (preserves attachments).

    Uses System Events to trigger Cmd+D after selecting the note.
    Notes.app must be running and accessible. Use --new-name to
    rename the duplicate immediately after creation.
    """
    script = f"""on run argv
tell application "Notes"
    {find_note()}
    show item 1 of matchedNotes
end tell
delay 1
tell application "System Events"
    tell process "Notes"
        keystroke "d" using {{command down}}
    end tell
end tell
delay 2
end run"""
    result = subprocess.run(
        ["osascript", "-e", script, folder, name],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        click.echo(f"Error: {result.stderr.strip()}", err=True)
        sys.exit(1)
    cache_invalidate()
    click.echo(f"Duplicated '{name}' in '{folder}'")

    if new_name:
        # After Cmd+D, the duplicate has the same name as the original.
        # Rename both name property and body title.
        _rename_note(folder, name, new_name)
        cache_invalidate()
        click.echo(f"Renamed duplicate to '{new_name}'")


# -- search -----------------------------------------------------------------

SEARCH_SCRIPT = """set matchedNotes to every note in folder (item 1 of argv) whose plaintext contains (item 2 of argv)
    set output to ""
    repeat with n in matchedNotes
        set output to output & name of n & linefeed
    end repeat
    return output"""


@cli.command()
@click.argument("query")
@click.option("--folder", default=None, help="Limit search to a specific folder.")
@click.option("--json", "as_json", is_flag=True, help="Output as JSON.")
def search(query, folder, as_json):
    """Search notes by content."""
    results = []
    if folder:
        output = run_osascript(SEARCH_SCRIPT, args=[folder, query])
        if output:
            for line in output.splitlines():
                if line:
                    results.append({"folder": folder, "name": line})
    else:
        folder_names = _get_folder_names()
        for fname in folder_names:
            output = run_osascript(SEARCH_SCRIPT, args=[fname, query])
            if output:
                for line in output.splitlines():
                    if line:
                        results.append({"folder": fname, "name": line})

    if as_json:
        click.echo(json.dumps(results, indent=2))
    else:
        for r in results:
            click.echo(f"{r['folder']}/{r['name']}")


# -- accounts ---------------------------------------------------------------

@cli.command()
@click.option("--json", "as_json", is_flag=True, help="Output as JSON.")
def accounts(as_json):
    """List all note accounts."""
    output = run_osascript("get name of every account")
    names = output.split(", ")
    if as_json:
        click.echo(json.dumps(names, indent=2))
    else:
        for name in names:
            click.echo(name)


# -- cache management -------------------------------------------------------

@cli.command("clear-cache")
def clear_cache():
    """Clear the notes cache."""
    cache_invalidate()
    click.echo("Cache cleared.")


if __name__ == "__main__":
    cli()
