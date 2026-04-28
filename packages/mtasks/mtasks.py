#!/usr/bin/env python3
"""Taskwarrior-style table view of markdown task files.

Recursively scans `--root` (default: cwd) for `*.md` files and parses
GitHub-style task lines (`- [ ] ...` / `- [x] ...`).

Usage:
  mtasks [--all|--pending|--completed] [--project P]
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
from rich.table import Table

TASK_RE = re.compile(r"^- \[( |x)\] (.*)$")
SUBKV_RE = re.compile(r"^  - ([A-Za-z][A-Za-z0-9_]*): (.*)$")


@dataclass
class Task:
    project: str = ""
    status: str = "pending"  # pending | done
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
    project: str | None = None
    limit: int | None = 20


def parse_file(path: Path, root: Path) -> list[Task]:
    rel = path.relative_to(root)
    # Project = relative parent dir, or "." if file is at root level
    project = str(rel.parent) if rel.parent != Path(".") else path.parent.name
    lines = path.read_text().splitlines()
    tasks: list[Task] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        m = TASK_RE.match(line)
        if not m:
            i += 1
            continue
        status = "done" if m.group(1) == "x" else "pending"
        title = m.group(2)

        t = Task(
            project=project,
            status=status,
            title=title,
            file=str(path),
            line=i + 1,
        )

        # Collect contiguous `  - key: value` continuation lines
        j = i + 1
        notes_extra: list[str] = []
        while j < len(lines):
            ln = lines[j]
            if not ln.startswith("  "):
                break
            sub = SUBKV_RE.match(ln)
            if sub:
                k, v = sub.group(1), sub.group(2).strip()
                t.extra[k] = v
            else:
                # free-form continuation bullet
                stripped = ln.strip().lstrip("- ").strip()
                if stripped:
                    notes_extra.append(stripped)
            j += 1

        explicit_notes = t.extra.get("notes", "")
        t.notes = " | ".join(x for x in [explicit_notes, *notes_extra] if x)

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
    pending = [t for t in out if t.status == "pending"]
    done = [t for t in out if t.status == "done"]
    return pending + done


def filter_tasks(tasks: list[Task], args) -> list[Task]:
    out = tasks
    if args.pending:
        out = [t for t in out if t.status == "pending"]
    elif args.completed:
        out = [t for t in out if t.status == "done"]
    elif not args.all:
        out = [t for t in out if t.status == "pending"]
    if args.project:
        wanted = {p.lower() for p in args.project.split(",")}
        out = [t for t in out if t.project.lower() in wanted]
    if args.limit:
        out = out[: args.limit]
    return out


def render_table(
    tasks: list[Task], totals: dict | None = None, wrap: bool = False
) -> str:
    show_status = any(t.status == "done" for t in tasks)
    width = shutil.get_terminal_size((100, 24)).columns
    table = Table(box=box.ROUNDED, expand=True)
    table.add_column(
        "Project", no_wrap=True, overflow="ellipsis", min_width=12, max_width=24
    )
    if show_status:
        table.add_column("Status", no_wrap=True, min_width=6, max_width=6)
    table.add_column(
        "Title", overflow="fold" if wrap else "ellipsis", no_wrap=not wrap, ratio=1
    )

    for t in tasks:
        row = [t.project]
        if show_status:
            row.append(t.status if t.status == "done" else "")
        table.add_row(*row, t.title, style="dim" if t.status == "done" else None)

    output = io.StringIO()
    console = Console(file=output, force_terminal=True, width=width)
    console.print(table)
    if totals:
        console.print(
            f"shown: {len(tasks)}  "
            f"total: {totals['total']} "
            f"(pending: {totals['pending']}, done: {totals['done']})"
        )
    else:
        console.print(f"{len(tasks)} tasks")
    return output.getvalue().rstrip()


def render_simple_table(
    tasks: list[Task], totals: dict | None = None, wrap: bool = False
) -> str:
    show_status = any(t.status == "done" for t in tasks)
    cols = [
        ("Project", lambda t: t.project),
    ]
    if show_status:
        cols.append(("Status", lambda t: t.status if t.status == "done" else ""))
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
                title = title[: max(1, title_width - 1)] + "…"
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
        if t.status == "done":
            line = f"\033[2m{line}\033[0m"
        out.append(line)
    out.append("")
    if totals:
        out.append(
            f"shown: {len(tasks)}  "
            f"total: {totals['total']} "
            f"(pending: {totals['pending']}, done: {totals['done']})"
        )
    else:
        out.append(f"{len(tasks)} tasks")
    return "\n".join(out)


@click.command(
    context_settings={"help_option_names": ["-h", "--help"]},
    help="Taskwarrior-style listing of markdown task files under a directory.",
)
@click.option(
    "--root",
    type=click.Path(path_type=Path, file_okay=False, dir_okay=True),
    envvar="MTASKS_ROOT",
    default=".",
    show_default=True,
    help="Root directory to scan recursively.",
)
@click.option("--all", "show_all", is_flag=True, help="Show all tasks.")
@click.option(
    "--pending", is_flag=True, help="Show pending tasks. This is the default."
)
@click.option("--completed", is_flag=True, help="Show completed tasks.")
@click.option("--project", help="Filter by project name, comma-separated.")
@click.option(
    "--limit",
    type=click.IntRange(min=0),
    default=None,
    metavar="N",
    help=(
        "Limit rows. Use 0 for no limit. "
        "Defaults to no limit with --all, otherwise 20."
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
    root: Path,
    show_all: bool,
    pending: bool,
    completed: bool,
    project: str | None,
    limit: int | None,
    output_format: str,
    wrap: bool,
):
    modes = [show_all, pending, completed]
    if sum(1 for mode in modes if mode) > 1:
        raise click.UsageError("Use only one of --all, --pending, or --completed.")

    if limit is None:
        limit = 0 if show_all else 20

    args = Options(
        all=show_all,
        pending=pending,
        completed=completed,
        project=project,
        limit=limit,
    )
    all_tasks = gather(root.resolve())
    tasks = filter_tasks(all_tasks, args)
    totals = {
        "total": len(all_tasks),
        "pending": sum(1 for t in all_tasks if t.status == "pending"),
        "done": sum(1 for t in all_tasks if t.status == "done"),
    }
    if output_format == "table":
        click.echo(render_table(tasks, totals, wrap=wrap))
    elif output_format == "simple":
        click.echo(render_simple_table(tasks, totals, wrap=wrap))
    else:
        click.echo(json.dumps([asdict(t) for t in tasks], indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main(prog_name="mtasks")
