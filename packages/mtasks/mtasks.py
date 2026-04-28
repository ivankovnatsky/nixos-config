#!/usr/bin/env python3
"""Taskwarrior-style table view of markdown task files.

Recursively scans `--root` (default: cwd) for `*.md` files and parses
GitHub-style task lines (`- [ ] ...` / `- [x] ...`).

Usage:
  mtasks [--all|--pending|--completed] [--project P]
       [--limit N] [--format table|tsv|json] [--root PATH]
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import textwrap
from dataclasses import dataclass, field, asdict
from pathlib import Path

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
    out: list[Task] = []
    for f in sorted(root.rglob("*.md")):
        # Skip hidden directories (e.g., .git, .obsidian)
        if any(part.startswith(".") for part in f.relative_to(root).parts):
            continue
        out.extend(parse_file(f, root))
    pending = [t for t in out if t.status == "pending"]
    done = [t for t in out if t.status == "done"]
    pending.sort(key=lambda t: (t.file, t.line))
    done.sort(key=lambda t: (t.file, t.line))
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
    cols = [
        ("Project", lambda t: t.project),
        ("Status", lambda t: t.status if t.status == "done" else ""),
        ("Title", lambda t: t.title),
    ]
    headers = [h for h, _ in cols]
    rows = [headers]
    for t in tasks:
        rows.append([fn(t) for _, fn in cols])
    # Compute widths from non-title columns; title is last and not padded.
    widths = [
        max(len(str(r[i])) for r in rows) if i < len(cols) - 1 else len(headers[i])
        for i in range(len(cols))
    ]

    # Title column starts at this column; wraps to (term_width - title_col).
    sep = "  "
    title_col = sum(widths[:-1]) + len(sep) * (len(cols) - 1)
    term_width = shutil.get_terminal_size((100, 24)).columns
    title_width = max(20, term_width - title_col)

    def fmt_row(r, mode: str):
        """mode: 'header' (no truncate/wrap), 'truncate', or 'wrap'."""
        prefix_cells = [str(r[i]).ljust(widths[i]) for i in range(len(cols) - 1)]
        prefix = sep.join(prefix_cells) + sep
        title = str(r[-1])
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
        rest = [pad + w for w in wrapped[1:]]
        return "\n".join([first, *rest])

    row_mode = "wrap" if wrap else "truncate"
    out = [fmt_row(rows[0], "header")]
    out.append("  ".join("-" * w for w in widths))
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


def render_tsv(tasks: list[Task]) -> str:
    headers = ["project", "status", "title"]
    lines = ["\t".join(headers)]
    for t in tasks:
        lines.append(
            "\t".join(
                [
                    t.project,
                    t.status,
                    t.title.replace("\t", " "),
                ]
            )
        )
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(
        description="Taskwarrior-style listing of markdown task files under a directory"
    )
    ap.add_argument(
        "--root",
        type=Path,
        default=Path(os.environ.get("MTASKS_ROOT", ".")).resolve(),
        help="root directory to scan recursively (default: cwd or $MTASKS_ROOT)",
    )
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--all", action="store_true", help="show all tasks")
    g.add_argument("--pending", action="store_true", help="show pending (default)")
    g.add_argument("--completed", action="store_true", help="show completed")
    ap.add_argument("--project", help="filter by project name (comma-separated)")
    ap.add_argument(
        "--limit", type=int, default=20, help="limit rows (default: 20, 0 = no limit)"
    )
    ap.add_argument("--format", choices=["table", "tsv", "json"], default="table")
    ap.add_argument(
        "--wrap",
        action="store_true",
        help="wrap long titles across multiple lines (default: truncate with …)",
    )
    args = ap.parse_args()

    all_tasks = gather(args.root)
    tasks = filter_tasks(all_tasks, args)
    totals = {
        "total": len(all_tasks),
        "pending": sum(1 for t in all_tasks if t.status == "pending"),
        "done": sum(1 for t in all_tasks if t.status == "done"),
    }
    if args.format == "table":
        print(render_table(tasks, totals, wrap=args.wrap))
    elif args.format == "tsv":
        print(render_tsv(tasks))
    else:
        print(json.dumps([asdict(t) for t in tasks], indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
