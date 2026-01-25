"""Display and formatting utilities for Rich output."""

import os
from rich.table import Table
from rich.markup import escape
from rich import box

from .config import (
    STATUS_DONE,
    STATUS_IN_PROGRESS,
    STATUS_BLOCKED,
    STATUS_TODO,
    DEFAULT_TERMINAL_WIDTH,
)
from .utils import truncate_text


def get_status_style(status_name):
    """Get rich style for status name.

    Colors chosen for color blindness accessibility:
    - Avoids red-green distinction (problematic for 8% of males)
    - Uses brightness/saturation differences alongside hue
    """
    status_lower = status_name.lower()
    if status_lower in STATUS_DONE:
        return "[dim strike]"  # Dimmed + strikethrough indicates completed
    elif status_lower in STATUS_IN_PROGRESS:
        return "[bold bright_cyan]"  # bright_cyan distinct from Reporter's blue
    elif status_lower in STATUS_BLOCKED:
        return "[bold bright_magenta]"  # Magenta instead of red for color blindness
    elif status_lower in STATUS_TODO:
        return "[yellow]"
    return "[white]"


def get_priority_style(priority_name):
    """Get rich style for priority.

    Uses style-based distinction (bold, underline, reverse) rather than
    color-only to be accessible for color blindness.
    No color repeats with cell attribute values.
    """
    if not priority_name:
        return "[dim]", "None"
    priority_lower = priority_name.lower()
    if priority_lower in ("highest", "blocker"):
        return "[bold reverse]", priority_name  # Inverted - maximum visibility
    elif priority_lower in ("high", "critical"):
        return "[bold underline]", priority_name
    elif priority_lower == "medium":
        return "[bright_black]", priority_name  # Gray - neutral
    elif priority_lower in ("low", "lowest", "minor", "trivial"):
        return "[dim italic]", priority_name
    return "[white]", priority_name


def format_issue_cell_fn(issue, col_width):
    """Format a single issue as a Rich-formatted cell string"""
    key = escape(issue.key)
    summary = escape(truncate_text(issue.fields.summary, col_width - 2))

    reporter = issue.fields.reporter.displayName if issue.fields.reporter else "Unknown"
    reporter = escape(truncate_text(reporter, col_width - 2))

    updated = (
        issue.fields.updated[:16].replace("T", " ") if issue.fields.updated else ""
    )

    resolution = (
        issue.fields.resolution.name if issue.fields.resolution else "Unresolved"
    )
    resolution = escape(resolution)

    priority = issue.fields.priority.name if issue.fields.priority else "None"
    prio_short = escape(priority[:3])
    prio_style, _ = get_priority_style(priority)

    assignee = (
        issue.fields.assignee.displayName if issue.fields.assignee else "Unassigned"
    )
    assignee = escape(truncate_text(assignee, col_width - 2))

    # Colors chosen for color blindness accessibility (high contrast, distinct hues)
    # Reporter uses [blue] to avoid overlap with In Progress status [bold bright_cyan]
    return (
        f"[dim]Summary:   [/] [bold yellow]{summary}[/]\n"
        f"[dim]Reporter:  [/] [blue]{reporter}[/]\n"
        f"[dim]Date:      [/] [bright_white]{updated}[/]\n"
        f"[dim]Resolution:[/] [magenta]{resolution}[/]\n"
        f"[dim]Key:       [/] [bold bright_blue]{key}[/]\n"
        f"[dim]Priority:  [/] {prio_style}{prio_short}[/]\n"
        f"[dim]Assignee:  [/] [bold bright_green]{assignee}[/]"
    )


def render_board_table_fn(console, issues_by_status, all_columns):
    """Render issues as a kanban board table"""
    # Calculate dynamic column width based on terminal size
    try:
        terminal_width = (
            int(os.getenv("COLUMNS", 0)) or console.width or DEFAULT_TERMINAL_WIDTH
        )
    except ValueError:
        terminal_width = console.width or DEFAULT_TERMINAL_WIDTH

    num_columns = len(all_columns)
    available_width = terminal_width - (num_columns + 1) * 3
    col_width = max(20, available_width // num_columns)

    table = Table(
        show_header=True,
        header_style="bold cyan",
        box=box.ROUNDED,
        padding=(0, 1),
        width=terminal_width,
    )

    for col_status in all_columns:
        count = len(issues_by_status.get(col_status, []))
        style = get_status_style(col_status)
        table.add_column(
            f"{style}{col_status}[/] ({count})",
            ratio=1,
            no_wrap=True,
            overflow="ellipsis",
        )

    max_rows = (
        max(len(issues_by_status.get(s, [])) for s in all_columns) if all_columns else 0
    )

    for row_idx in range(max_rows):
        row_data = []
        for col_status in all_columns:
            col_issues = issues_by_status.get(col_status, [])
            if row_idx < len(col_issues):
                row_data.append(format_issue_cell_fn(col_issues[row_idx], col_width))
            else:
                row_data.append("")
        table.add_row(*row_data)
        if row_idx < max_rows - 1:
            table.add_section()

    console.print(table)

    # Summary stats
    total = sum(len(issues_by_status[s]) for s in issues_by_status)
    stats_parts = [f"[bold]{total}[/bold] issues"]
    for s, issues in sorted(issues_by_status.items(), key=lambda x: -len(x[1])):
        style = get_status_style(s)
        stats_parts.append(f"{style}{len(issues)} {s}[/]")
    console.print(" | ".join(stats_parts))
