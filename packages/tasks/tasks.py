#!/usr/bin/env python3
"""Table view of markdown task files.

Recursively scans `--root` for `*.md` files and parses multiple task
formats simultaneously. The default root is the `Tasks/` subdirectory of
the Obsidian notes vault — iCloud Obsidian container on Macs
(`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes/Tasks`),
`~/Notes/Tasks` on a3 — falling back to cwd if neither path exists.

- TaskForge inline (Obsidian Tasks): checkbox states `[ /!>x-]` plus emoji
  metadata (➕ created, 🛫 start, ⏳ scheduled, 📅 due, ✅ done, ❌ cancelled,
  priority 🔺⏫🔼🔽⏬, `#tag`s, and ` — ` notes separator).
- TaskNote files: YAML frontmatter with `title`, `status`, optional
  `taskSourceType: taskNotes`, and a free-form markdown body.

Usage:
  tasks [--all|--pending|--completed] [--project P]
      [--limit N] [--format table|simple|json] [--root PATH]
"""

from __future__ import annotations

import io
import json
import re
import shutil
import textwrap
from dataclasses import dataclass, field, asdict
from pathlib import Path

import click
from rich import box
from rich.console import Console
from rich.markup import escape as rich_escape
from rich.table import Table

NOTES_CANDIDATES = (
    "Library/Mobile Documents/iCloud~md~obsidian/Documents/notes",
    "Notes",
)


def resolve_default_root() -> Path:
    """Default scan root: `<notes-vault>/Tasks` if it exists, else cwd.

    Mirrors the `notes` skill detection: iCloud Obsidian container on Macs,
    `~/Notes` on a3.
    """
    home = Path.home()
    for rel in NOTES_CANDIDATES:
        tasks = home / rel / "Tasks"
        if tasks.is_dir():
            return tasks
    return Path.cwd()


TASK_RE = re.compile(r"^- \[([ x/!>\-])\] (.*)$")
SUBKV_RE = re.compile(r"^  - ([A-Za-z][A-Za-z0-9_]*): (.*)$")

CHECKBOX_STATUS = {
    " ": "todo",
    "/": "in-progress",
    "!": "on-hold",
    ">": "planned",
    "x": "done",
    "-": "cancelled",
}

PENDING_STATUSES = {"todo", "in-progress", "on-hold", "planned"}
COMPLETED_STATUSES = {"done", "cancelled"}
KNOWN_STATUSES = PENDING_STATUSES | COMPLETED_STATUSES

INLINE_DATE_EMOJI = {
    "➕": "createdDate",  # ➕
    "\U0001f6eb": "start",  # 🛫
    "⏳": "scheduled",  # ⏳
    "\U0001f4c5": "due",  # 📅
    "✅": "completedDate",  # ✅
    "❌": "cancelledDate",  # ❌
}

PRIORITY_EMOJI = {
    "\U0001f53a": "highest",  # 🔺
    "⏫": "high",  # ⏫
    "\U0001f53c": "medium",  # 🔼
    "\U0001f53d": "low",  # 🔽
    "⏬": "lowest",  # ⏬
}

INLINE_DATE_RE = re.compile(
    "("
    + "|".join(re.escape(e) for e in INLINE_DATE_EMOJI)
    + r")\s*(\d{4}-\d{2}-\d{2})(?=\s|$)"
)
INLINE_PRIORITY_RE = re.compile(
    "(" + "|".join(re.escape(e) for e in PRIORITY_EMOJI) + ")"
)
TAG_RE = re.compile(r"(?:^|\s)#([A-Za-z][\w/]*(?:-[\w/]+)*)")
PAREN_BLOCK_RE = re.compile(r"\(([^()]*)\)")
PAREN_KV_RE = re.compile(
    r"^(created|completed|due|cancelled|started|scheduled):\s*(.*)$",
    re.IGNORECASE,
)
FM_DELIM = "---"
FM_KEY_RE = re.compile(r"^([A-Za-z][\w-]*):\s*(.*)$")


@dataclass
class Task:
    project: str = ""
    status: str = "todo"
    title: str = ""
    notes: str = ""
    file: str = ""
    line: int = 0
    extra: dict = field(default_factory=dict)


@dataclass
class Options:
    all: bool = False
    pending: bool = False
    completed: bool = False
    done: bool = False
    cancelled: bool = False
    project: str | None = None
    limit: int | None = 20


def _strip_quotes(s: str) -> str:
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ("'", '"'):
        return s[1:-1]
    return s


def parse_inline_meta(text: str) -> tuple[str, dict, list[str]]:
    """Strip TaskForge emoji/tag metadata from a checkbox title.

    Returns (cleaned_text, extras_dict, tags_list).
    """
    extras: dict = {}
    tags: list[str] = []

    def tag_sub(m: re.Match) -> str:
        tags.append(m.group(1))
        return " "

    text = TAG_RE.sub(tag_sub, text)

    def pri_sub(m: re.Match) -> str:
        extras["priority"] = PRIORITY_EMOJI[m.group(1)]
        return " "

    text = INLINE_PRIORITY_RE.sub(pri_sub, text)

    def date_sub(m: re.Match) -> str:
        extras.setdefault(INLINE_DATE_EMOJI[m.group(1)], m.group(2))
        return " "

    text = INLINE_DATE_RE.sub(date_sub, text)
    text = re.sub(r"\s+", " ", text).strip()
    return text, extras, tags


def parse_paren_tail(text: str) -> tuple[str, dict]:
    """Strip a legacy `(key: val, key: val)` metadata block from a title.

    Scans `(...)` blocks rightmost-first and strips the first one whose
    contents parse entirely as `key: value` pairs. This lets a trailing
    non-meta paren (e.g. `(note)`) coexist with a meta block earlier in the
    title.
    """
    matches = list(PAREN_BLOCK_RE.finditer(text))
    for m in reversed(matches):
        parts = [p.strip() for p in m.group(1).split(",") if p.strip()]
        if not parts:
            continue
        candidate: dict = {}
        ok = True
        for p in parts:
            kv = PAREN_KV_RE.match(p)
            if not kv:
                ok = False
                break
            candidate[kv.group(1).lower()] = kv.group(2).strip()
        if ok:
            new_text = text[: m.start()] + " " + text[m.end() :]
            new_text = re.sub(r"\s+", " ", new_text).strip()
            return new_text, candidate
    return text, {}


def split_title_notes(text: str) -> tuple[str, str]:
    parts = text.split(" — ", 1)  # ` — ` em-dash separator
    if len(parts) == 2:
        return parts[0].strip(), parts[1].strip()
    return text.strip(), ""


def parse_frontmatter(lines: list[str]) -> tuple[dict, int]:
    """Parse YAML-ish frontmatter at the top of `lines`.

    Supports scalar values (with optional quotes), flow lists `[a, b]`, and
    block lists (`key:` followed by `  - item` lines). Returns (data, body_start_index).
    Returns ({}, 0) if no frontmatter is present or it never closes.
    """
    if not lines or lines[0].strip() != FM_DELIM:
        return {}, 0
    data: dict = {}
    current_list_key: str | None = None
    i = 1
    while i < len(lines):
        ln = lines[i]
        if ln.strip() == FM_DELIM:
            return data, i + 1
        if current_list_key is not None and ln.startswith("  - "):
            data[current_list_key].append(_strip_quotes(ln[4:].strip()))
            i += 1
            continue
        current_list_key = None
        m = FM_KEY_RE.match(ln)
        if m:
            key, val = m.group(1), m.group(2).strip()
            if val == "":
                data[key] = []
                current_list_key = key
            elif val.startswith("[") and val.endswith("]"):
                inner = val[1:-1]
                data[key] = [_strip_quotes(x) for x in inner.split(",") if x.strip()]
            else:
                data[key] = _strip_quotes(val)
        i += 1
    return {}, 0


TASKNOTE_FIELDS = (
    "createdDate",
    "dateCreated",
    "completedDate",
    "cancelledDate",
    "due",
    "dueAt",
    "scheduled",
    "start",
    "priority",
    "project",
    "context",
    "recurrence",
    "taskSourceType",
)


def make_tasknote(
    fm: dict, body_lines: list[str], path: Path, project: str
) -> Task | None:
    status = fm.get("status")
    title = fm.get("title", "")
    is_tasknote = fm.get("taskSourceType") == "taskNotes" or (
        isinstance(status, str) and status in KNOWN_STATUSES and title
    )
    if not is_tasknote:
        return None

    extra: dict = {}
    for k in TASKNOTE_FIELDS:
        v = fm.get(k)
        if v:
            extra[k] = v
    tags = fm.get("tags")
    if isinstance(tags, list) and tags:
        extra["tags"] = ",".join(tags)
    elif isinstance(tags, str) and tags:
        extra["tags"] = tags

    body = "\n".join(body_lines).strip()
    notes = " ".join(body.split())

    return Task(
        project=project,
        status=status if status in KNOWN_STATUSES else "todo",
        title=title,
        notes=notes,
        file=str(path),
        line=1,
        extra=extra,
    )


def parse_file(path: Path, root: Path) -> list[Task]:
    rel = path.relative_to(root)
    project = str(rel.parent) if rel.parent != Path(".") else path.parent.name

    try:
        lines = path.read_text().splitlines()
    except (OSError, UnicodeDecodeError):
        return []

    tasks: list[Task] = []

    fm, body_start = parse_frontmatter(lines)
    if fm:
        body_lines = lines[body_start:]
        tn = make_tasknote(fm, body_lines, path, project)
        if tn is not None:
            # The TaskNote IS the task; body checkboxes are its sub-checklist
            # and should not surface as their own top-level tasks.
            tasks.append(tn)
            return tasks
        scan_lines = lines[body_start:]
        scan_offset = body_start
    else:
        scan_lines = lines
        scan_offset = 0

    i = 0
    while i < len(scan_lines):
        line = scan_lines[i]
        m = TASK_RE.match(line)
        if not m:
            i += 1
            continue

        status = CHECKBOX_STATUS.get(m.group(1), "todo")
        raw = m.group(2)

        cleaned, inline_extras, tags = parse_inline_meta(raw)
        cleaned, paren_extras = parse_paren_tail(cleaned)
        title, notes_inline = split_title_notes(cleaned)

        t = Task(
            project=project,
            status=status,
            title=title,
            file=str(path),
            line=scan_offset + i + 1,
        )
        if tags:
            t.extra["tags"] = ",".join(tags)
        # Precedence: inline emoji meta > sub-bullet meta > legacy paren tail.
        # Inline is the canonical TaskForge source; legacy formats only fill
        # gaps inline didn't supply.
        t.extra.update(inline_extras)
        for k, v in paren_extras.items():
            t.extra.setdefault(k, v)

        j = i + 1
        notes_extra: list[str] = []
        while j < len(scan_lines):
            ln = scan_lines[j]
            if not ln.startswith("  "):
                break
            sub = SUBKV_RE.match(ln)
            if sub:
                k, v = sub.group(1), sub.group(2).strip()
                t.extra.setdefault(k, v)
            else:
                stripped = ln.strip().lstrip("- ").strip()
                if stripped:
                    notes_extra.append(stripped)
            j += 1

        explicit_notes = t.extra.pop("notes", "")
        t.notes = " | ".join(
            x for x in [notes_inline, explicit_notes, *notes_extra] if x
        )

        tasks.append(t)
        i = j
    return tasks


def gather(root: Path) -> list[Task]:
    files = [
        f
        for f in root.rglob("*.md")
        if not any(part.startswith(".") for part in f.relative_to(root).parts)
    ]
    files.sort(key=lambda f: f.stat().st_mtime)
    out: list[Task] = []
    for f in files:
        out.extend(parse_file(f, root))
    pending = [t for t in out if t.status in PENDING_STATUSES]
    done = [t for t in out if t.status in COMPLETED_STATUSES]
    other = [t for t in out if t.status not in KNOWN_STATUSES]
    return pending + done + other


def filter_tasks(tasks: list[Task], args) -> list[Task]:
    out = tasks
    if args.pending:
        out = [t for t in out if t.status in PENDING_STATUSES]
    elif args.completed:
        out = [t for t in out if t.status in COMPLETED_STATUSES]
    elif args.done:
        out = [t for t in out if t.status == "done"]
    elif args.cancelled:
        out = [t for t in out if t.status == "cancelled"]
    elif not args.all:
        out = [t for t in out if t.status in PENDING_STATUSES]
    if args.project:
        wanted = {p.lower() for p in args.project.split(",")}
        out = [t for t in out if t.project.lower() in wanted]
    if args.limit:
        out = out[: args.limit]
    return out


def _show_status_column(tasks: list[Task]) -> bool:
    return any(t.status != "todo" for t in tasks)


def _status_cell(t: Task) -> str:
    return "" if t.status == "todo" else t.status


def render_table(
    tasks: list[Task], totals: dict | None = None, wrap: bool = False
) -> str:
    show_status = _show_status_column(tasks)
    width = shutil.get_terminal_size((100, 24)).columns
    table = Table(box=box.ROUNDED, expand=True)
    table.add_column(
        "Project", no_wrap=True, overflow="ellipsis", min_width=12, max_width=24
    )
    if show_status:
        table.add_column("Status", no_wrap=True, min_width=11, max_width=12)
    table.add_column(
        "Title", overflow="fold" if wrap else "ellipsis", no_wrap=not wrap, ratio=1
    )

    for t in tasks:
        row = [rich_escape(t.project)]
        if show_status:
            row.append(rich_escape(_status_cell(t)))
        table.add_row(
            *row,
            rich_escape(t.title),
            style="dim" if t.status in COMPLETED_STATUSES else None,
        )

    output = io.StringIO()
    console = Console(file=output, force_terminal=True, width=width)
    console.print(table)
    if totals:
        console.print(
            f"shown: {len(tasks)}  "
            f"total: {totals['total']} "
            f"(pending: {totals['pending']}, "
            f"done: {totals['done']}, "
            f"cancelled: {totals['cancelled']})"
        )
    else:
        console.print(f"{len(tasks)} tasks")
    return output.getvalue().rstrip()


def render_simple_table(
    tasks: list[Task], totals: dict | None = None, wrap: bool = False
) -> str:
    show_status = _show_status_column(tasks)
    cols: list[tuple[str, callable]] = [("Project", lambda t: t.project)]
    if show_status:
        cols.append(("Status", _status_cell))
    cols.append(("Title", lambda t: t.title))
    headers = [h for h, _ in cols]
    rows = [headers]
    for t in tasks:
        rows.append([fn(t) for _, fn in cols])
    widths = [
        max(len(str(r[i])) for r in rows) if i < len(cols) - 1 else len(headers[i])
        for i in range(len(cols))
    ]

    sep = "  "
    title_col = sum(widths[:-1]) + len(sep) * (len(cols) - 1)
    term_width = shutil.get_terminal_size((100, 24)).columns
    title_width = max(20, term_width - title_col)

    def fmt_row(row, mode: str):
        prefix_cells = [str(row[i]).ljust(widths[i]) for i in range(len(cols) - 1)]
        prefix = sep.join(prefix_cells) + sep
        title = str(row[-1])
        if mode == "header":
            return (prefix + title).rstrip()
        if mode == "truncate":
            if len(title) > title_width:
                title = title[: max(1, title_width - 1)] + ".."
            return (prefix + title).rstrip()
        wrapped = textwrap.wrap(
            title, width=title_width, break_long_words=False, break_on_hyphens=False
        ) or [""]
        pad = " " * title_col
        first = (prefix + wrapped[0]).rstrip()
        rest = [pad + line for line in wrapped[1:]]
        return "\n".join([first, *rest])

    row_mode = "wrap" if wrap else "truncate"
    out = [fmt_row(rows[0], "header")]
    out.append("  ".join("-" * width for width in widths))
    for i, t in enumerate(tasks, 1):
        line = fmt_row(rows[i], row_mode)
        if t.status in COMPLETED_STATUSES:
            line = f"\033[2m{line}\033[0m"
        out.append(line)
    out.append("")
    if totals:
        out.append(
            f"shown: {len(tasks)}  "
            f"total: {totals['total']} "
            f"(pending: {totals['pending']}, "
            f"done: {totals['done']}, "
            f"cancelled: {totals['cancelled']})"
        )
    else:
        out.append(f"{len(tasks)} tasks")
    return "\n".join(out)


@click.command(
    context_settings={"help_option_names": ["-h", "--help"]},
    help="Listing of markdown task files under a directory.",
)
@click.option(
    "--root",
    type=click.Path(path_type=Path, file_okay=False, dir_okay=True),
    envvar="TASKS_ROOT",
    default=None,
    help=(
        "Root directory to scan recursively. Defaults to the Obsidian vault's "
        "Tasks/ subdirectory (iCloud path on Macs, ~/Notes/Tasks on a3); falls "
        "back to cwd if neither exists."
    ),
)
@click.option("--all", "show_all", is_flag=True, help="Show all tasks.")
@click.option(
    "--pending", is_flag=True, help="Show pending tasks. This is the default."
)
@click.option(
    "--completed",
    is_flag=True,
    help="Show completed tasks (done or cancelled).",
)
@click.option("--done", is_flag=True, help="Show done tasks only.")
@click.option("--cancelled", is_flag=True, help="Show cancelled tasks only.")
@click.option("--project", help="Filter by project name, comma-separated.")
@click.option(
    "--limit",
    type=click.IntRange(min=0),
    default=None,
    metavar="N",
    help=(
        "Limit rows. Use 0 for no limit. Defaults to no limit with --all, otherwise 20."
    ),
)
@click.option(
    "--format",
    "output_format",
    type=click.Choice(["table", "simple", "json"]),
    default="table",
    show_default=True,
    help="Output format. table is the Rich view.",
)
@click.option(
    "--wrap",
    is_flag=True,
    help="Wrap long titles across multiple lines. The default truncates.",
)
def main(
    root: Path | None,
    show_all: bool,
    pending: bool,
    completed: bool,
    done: bool,
    cancelled: bool,
    project: str | None,
    limit: int | None,
    output_format: str,
    wrap: bool,
):
    modes = [show_all, pending, completed, done, cancelled]
    if sum(1 for mode in modes if mode) > 1:
        raise click.UsageError(
            "Use only one of --all, --pending, --completed, --done, or --cancelled."
        )

    if limit is None:
        limit = 0 if show_all else 20

    args = Options(
        all=show_all,
        pending=pending,
        completed=completed,
        done=done,
        cancelled=cancelled,
        project=project,
        limit=limit,
    )
    scan_root = root if root is not None else resolve_default_root()
    all_tasks = gather(scan_root.resolve())
    tasks = filter_tasks(all_tasks, args)
    totals = {
        "total": len(all_tasks),
        "pending": sum(1 for t in all_tasks if t.status in PENDING_STATUSES),
        "done": sum(1 for t in all_tasks if t.status == "done"),
        "cancelled": sum(1 for t in all_tasks if t.status == "cancelled"),
    }
    if output_format == "table":
        click.echo(render_table(tasks, totals, wrap=wrap))
    elif output_format == "simple":
        click.echo(render_simple_table(tasks, totals, wrap=wrap))
    else:
        click.echo(json.dumps([asdict(t) for t in tasks], indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main(prog_name="tasks")
