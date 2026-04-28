#!/usr/bin/env python3
"""Taskwarrior-style table view of markdown task files.

Recursively scans `--root` (default: cwd) for `*.md` files and parses
GitHub-style task lines (`- [ ] ...` / `- [x] ...`).

Usage:
  mtdo [--all|--pending|--completed] [--project P] [--overdue]
       [--due today|week] [--limit N] [--format table|tsv|json] [--root PATH]

Parses two coexisting formats:
  1. Inline parens:  - [ ] Title (created: 2026-03-20, due: 2026-04-09)
  2. YAML-ish sub:   - [x] Title
                       - createdDate: 2026-04-21 09:45Z
                       - due: 2026-04-21 16:00Z
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import textwrap
from dataclasses import dataclass, field, asdict
from datetime import datetime, date, timedelta
from pathlib import Path

TASK_RE = re.compile(r"^- \[( |x)\] (.*)$")
SUBKV_RE = re.compile(r"^  - ([A-Za-z][A-Za-z0-9_]*): (.*)$")
INLINE_META_RE = re.compile(r"\(([^()]*?(?:created|due|completed)[^()]*)\)\s*$")


@dataclass
class Task:
    project: str = ""
    status: str = "pending"  # pending | done
    title: str = ""
    created: str = ""
    due: str = ""
    completed: str = ""
    priority: str = ""
    notes: str = ""
    file: str = ""
    line: int = 0
    extra: dict = field(default_factory=dict)


def parse_inline_meta(title: str) -> tuple[str, dict]:
    """Pull `(created: ..., due: ..., completed: ...)` off the end of a title."""
    m = INLINE_META_RE.search(title)
    if not m:
        return title, {}
    inner = m.group(1)
    # Only treat as metadata if every comma-segment is `key: value`
    parts = [p.strip() for p in inner.split(",")]
    meta = {}
    for p in parts:
        if ":" not in p:
            return title, {}
        k, v = p.split(":", 1)
        meta[k.strip()] = v.strip()
    return title[: m.start()].rstrip(), meta


def normalize_date(s: str) -> str:
    """Return YYYY-MM-DD if parseable, else original string."""
    if not s:
        return ""
    s = s.strip()
    # `2026-04-21 09:45Z` or `2026-04-21`
    for fmt in ("%Y-%m-%d %H:%MZ", "%Y-%m-%dT%H:%M:%SZ", "%Y-%m-%d"):
        try:
            return datetime.strptime(s, fmt).strftime("%Y-%m-%d")
        except ValueError:
            pass
    return s


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
        raw_title = m.group(2)
        title, inline_meta = parse_inline_meta(raw_title)

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

        # Map metadata from both formats
        ex = t.extra
        t.created = normalize_date(
            inline_meta.get("created") or ex.get("createdDate") or ex.get("created", "")
        )
        t.due = normalize_date(inline_meta.get("due") or ex.get("due", ""))
        t.completed = normalize_date(
            inline_meta.get("completed")
            or ex.get("completedDate")
            or ex.get("completed", "")
        )
        t.priority = ex.get("priority", "")
        explicit_notes = ex.get("notes", "")
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
    # Pending first (urgency-ish ordering), then done
    pending = [t for t in out if t.status == "pending"]
    done = [t for t in out if t.status == "done"]
    pending.sort(key=lambda t: (t.due or "9999-99-99", t.file, t.line))
    done.sort(key=lambda t: t.completed, reverse=True)
    return pending + done


def filter_tasks(tasks: list[Task], args) -> list[Task]:
    today = date.today().isoformat()
    week = (date.today() + timedelta(days=7)).isoformat()
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
    if args.overdue:
        out = [t for t in out if t.due and t.due < today and t.status == "pending"]
    if args.due == "today":
        out = [t for t in out if t.due == today]
    elif args.due == "week":
        out = [t for t in out if t.due and today <= t.due <= week]
    if args.limit:
        out = out[: args.limit]
    return out


def render_table(
    tasks: list[Task], totals: dict | None = None, wrap: bool = False
) -> str:
    cols = [
        ("Pr", lambda t: t.priority or ""),
        ("Project", lambda t: t.project),
        ("S", lambda t: "x" if t.status == "done" else " "),
        ("Created", lambda t: t.created or ""),
        ("Due", lambda t: t.due or ""),
        ("Done", lambda t: t.completed or ""),
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
    today = date.today().isoformat()

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
        if t.due and t.due < today and t.status == "pending":
            line = f"\033[31m{line}\033[0m"
        elif t.due == today:
            line = f"\033[33m{line}\033[0m"
        elif t.status == "done":
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
    headers = [
        "project",
        "status",
        "priority",
        "created",
        "due",
        "completed",
        "title",
    ]
    lines = ["\t".join(headers)]
    for t in tasks:
        lines.append(
            "\t".join(
                [
                    t.project,
                    t.status,
                    t.priority,
                    t.created,
                    t.due,
                    t.completed,
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
    ap.add_argument("--overdue", action="store_true", help="only overdue pending")
    ap.add_argument(
        "--due", choices=["today", "week"], help="due today or within a week"
    )
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
