"""Formatting and display functions for drift reports."""

import difflib

import click

from utils import (
    FIELD_DISPLAY_NAMES,
    format_date,
    format_date_local,
    infer_flow,
)


def format_notes_diff(from_text, to_text, indent="        "):
    """Render a notes diff with colored lines (red=deletion, green=addition)."""
    from_lines = from_text.splitlines()
    to_lines = to_text.splitlines()
    diff = difflib.unified_diff(from_lines, to_lines, lineterm="")
    lines = []
    for line in diff:
        if line.startswith("---") or line.startswith("+++"):
            continue
        if line.startswith("@@"):
            continue
        if line.startswith("-"):
            lines.append(f"{indent}{click.style(line, fg='red')}")
        elif line.startswith("+"):
            lines.append(f"{indent}{click.style(line, fg='green')}")
        else:
            lines.append(f"{indent}{line}")
    return "\n".join(lines) if lines else None


def print_drift_item(key, info, direction=None):
    """Print drift for a single metadata item."""
    project, title = key
    click.echo(f"  {project}: {title}")
    groups = {}
    for field, rem_val, tw_val in info["diffs"]:
        if direction == "reminders":
            flow = "rem_to_tw"
        elif direction == "tw":
            flow = "tw_to_rem"
        else:
            flow = infer_flow(field, rem_val, tw_val)
        if flow == "rem_to_tw":
            groups.setdefault("Reminders \u2192 Taskwarrior:", []).append(
                (field, tw_val, rem_val)
            )
        else:
            groups.setdefault("Taskwarrior \u2192 Reminders:", []).append(
                (field, rem_val, tw_val)
            )
    for header, fields in groups.items():
        click.echo(f"    {header}")
        for field, from_val, to_val in fields:
            if field == "notes":
                tw_ann = [
                    a.get("description", "") for a in info["tw"].get("annotations", [])
                ]
                raw_tw = "; ".join(tw_ann) if tw_ann else ""
                raw_rem = (info["rem"].get("notes") or "").strip()
                if "Reminders" in header and header.endswith("Taskwarrior:"):
                    raw_from, raw_to = raw_tw, raw_rem
                else:
                    raw_from, raw_to = raw_rem, raw_tw
                diff_output = format_notes_diff(raw_from, raw_to)
                if diff_output:
                    click.echo(f"      {field}:")
                    click.echo(diff_output)
                else:
                    click.echo(f"      {field}: {from_val} \u2192 {to_val}")
            else:
                click.echo(f"      {field}: {from_val} \u2192 {to_val}")


def format_item_summary(item):
    """Format an item for drift display with status and date info."""
    status = " (completed)" if item["status"] == "completed" else ""
    due = item.get("due", "")
    if due:
        due_display = format_date(due)
        return f"{item['project']}: {item['title']}{status} [due: {due_display}]"
    return f"{item['project']}: {item['title']}{status}"


def print_drift(rem_only, tw_only, matched, metadata_diffs, direction=None):
    """Print the drift report."""
    printed = False
    if rem_only:
        click.echo("Reminders only:")
        for item in rem_only.values():
            click.echo(f"  {format_item_summary(item)}")
        printed = True

    if tw_only:
        if printed:
            click.echo()
        click.echo("Taskwarrior only:")
        for item in tw_only.values():
            click.echo(f"  {format_item_summary(item)}")
        printed = True

    if metadata_diffs:
        if printed:
            click.echo()
        click.echo(f"Metadata drift ({len(metadata_diffs)} items):")
        for key, info in metadata_diffs.items():
            print_drift_item(key, info, direction=direction)
        printed = True

    if rem_only or tw_only or metadata_diffs:
        if printed:
            click.echo()
        click.echo(f"Matched: {len(matched)} items (skipped)")
        if rem_only:
            click.echo(f"Reminders only: {len(rem_only)}")
        if tw_only:
            click.echo(f"Taskwarrior only: {len(tw_only)}")
        if metadata_diffs:
            click.echo(f"Metadata drift: {len(metadata_diffs)}")


def format_update_summary(updates):
    """Format update keys as readable field names with values."""
    parts = []
    for key, val in updates.items():
        name = FIELD_DISPLAY_NAMES.get(key, key)
        display_val = format_date_local(val) if key in ("due", "end", "entry") else val
        parts.append(f"{name}: {display_val}")
    return "\n    ".join(parts)
