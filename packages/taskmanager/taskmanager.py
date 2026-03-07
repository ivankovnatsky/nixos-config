#!/usr/bin/env python3
"""Taskmanager: unified task management across Apple Reminders and Taskwarrior."""

import json
import platform
import shutil
import subprocess
import sys

import click


def has_command(cmd):
    return shutil.which(cmd) is not None


def is_darwin():
    return platform.system() == "Darwin"


def run(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        click.echo(
            f"Error running {' '.join(cmd)}: {result.stderr.strip()}", err=True
        )
    return result


def get_tw_tasks(project_filter=None):
    """Export tasks from Taskwarrior as a dict keyed by (project, title)."""
    cmd = ["task"]
    if project_filter:
        cmd.append(f"project.is:{project_filter}")
    cmd.append("export")

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return {}

    tasks = {}
    for task in json.loads(result.stdout):
        project = task.get("project", "")
        desc = task.get("description", "")
        status = task.get("status", "pending")

        # Strip project prefix from description if present
        prefix = f"{project}: "
        if desc.startswith(prefix):
            title = desc[len(prefix):]
        else:
            title = desc

        key = (project, title)
        tasks[key] = {
            "project": project,
            "title": title,
            "status": status,
            "source": "taskwarrior",
            "due": task.get("due", ""),
            "annotations": task.get("annotations", []),
            "priority": task.get("priority", ""),
        }
    return tasks


def get_reminders(project_filter=None, include_completed=True):
    """Export reminders as a dict keyed by (list, title)."""
    if not (is_darwin() and has_command("reminders")):
        return {}

    if project_filter:
        lists = [project_filter]
    else:
        result = subprocess.run(
            ["reminders", "show-lists"], capture_output=True, text=True
        )
        if result.returncode != 0:
            return {}
        lists = result.stdout.strip().splitlines()

    reminders = {}

    for list_name in lists:
        show_args = ["reminders", "show", list_name, "--format", "json"]
        if include_completed:
            show_args.append("--include-completed")

        result = subprocess.run(show_args, capture_output=True, text=True)
        if result.returncode != 0:
            continue

        try:
            items = json.loads(result.stdout)
        except json.JSONDecodeError:
            continue

        for item in items:
            title = item.get("title", "")
            is_completed = item.get("isCompleted", False)

            # Strip list prefix from title if present
            prefix = f"{list_name}: "
            if title.startswith(prefix):
                title = title[len(prefix):]

            key = (list_name, title)
            reminders[key] = {
                "project": list_name,
                "title": title,
                "status": "completed" if is_completed else "pending",
                "source": "reminders",
                "due": item.get("dueDate", ""),
                "notes": item.get("notes", ""),
                "priority": item.get("priority", 0),
            }
    return reminders


REMINDERS_PRIORITY_MAP = {0: "", 1: "H", 5: "M", 9: "L"}
PRIORITY_LABEL = {"H": "high", "M": "medium", "L": "low", "": "none"}


def normalize_date(date_str):
    """Normalize date to YYYY-MM-DD for comparison."""
    if not date_str:
        return ""
    clean = date_str.replace("-", "").replace(":", "")
    if len(clean) >= 8:
        d = clean[:8]
        return f"{d[:4]}-{d[4:6]}-{d[6:8]}"
    return date_str


def compare_metadata(tw, rem):
    """Compare metadata fields between matched TW and Reminders items."""
    diffs = []

    # Status
    if tw["status"] != rem["status"]:
        diffs.append(("status", rem["status"], tw["status"]))

    # Due date
    tw_due = normalize_date(tw.get("due", ""))
    rem_due = normalize_date(rem.get("due", ""))
    if tw_due != rem_due:
        diffs.append(("due", rem_due or "none", tw_due or "none"))

    # Notes vs annotations
    rem_notes = (rem.get("notes") or "").strip()
    tw_annotations = tw.get("annotations", [])
    tw_ann_texts = [a.get("description", "") for a in tw_annotations]
    if rem_notes:
        found = any(rem_notes in text for text in tw_ann_texts)
        if not found:
            diffs.append(("notes", repr(rem_notes[:60]), "not in annotations"))
    elif tw_ann_texts:
        joined = "; ".join(tw_ann_texts)
        diffs.append(("notes", "none", f"annotations: {repr(joined[:60])}"))

    # Priority
    rem_prio = REMINDERS_PRIORITY_MAP.get(rem.get("priority", 0), "")
    tw_prio = tw.get("priority", "")
    if rem_prio != tw_prio:
        diffs.append((
            "priority",
            PRIORITY_LABEL.get(rem_prio, rem_prio),
            PRIORITY_LABEL.get(tw_prio, tw_prio),
        ))

    return diffs


def compute_drift(project_filter=None):
    """Compute drift between Reminders and Taskwarrior."""
    click.echo("Loading Taskwarrior tasks...", err=True)
    tw_tasks = get_tw_tasks(project_filter)

    click.echo("Loading Reminders...", err=True)
    reminder_tasks = get_reminders(project_filter)

    tw_keys = set(tw_tasks.keys())
    rem_keys = set(reminder_tasks.keys())

    matched = tw_keys & rem_keys
    tw_only = {k: tw_tasks[k] for k in sorted(tw_keys - rem_keys)}
    rem_only = {k: reminder_tasks[k] for k in sorted(rem_keys - tw_keys)}

    metadata_diffs = {}
    for key in sorted(matched):
        diffs = compare_metadata(tw_tasks[key], reminder_tasks[key])
        if diffs:
            metadata_diffs[key] = diffs

    return rem_only, tw_only, matched, metadata_diffs


def print_drift(rem_only, tw_only, matched, metadata_diffs):
    """Print the drift report."""
    if rem_only:
        click.echo("\nReminders only:")
        for item in rem_only.values():
            status = " (completed)" if item["status"] == "completed" else ""
            click.echo(f"  {item['project']}: {item['title']}{status}")

    if tw_only:
        click.echo("\nTaskwarrior only:")
        for item in tw_only.values():
            status = " (completed)" if item["status"] == "completed" else ""
            click.echo(f"  {item['project']}: {item['title']}{status}")

    if metadata_diffs:
        click.echo(f"\nMetadata drift ({len(metadata_diffs)} items):")
        for (project, title), diffs in metadata_diffs.items():
            click.echo(f"  {project}: {title}")
            for field, rem_val, tw_val in diffs:
                click.echo(f"    {field}: {rem_val} (Reminders) vs {tw_val} (TW)")

    if not rem_only and not tw_only and not metadata_diffs:
        click.echo("\nNo drift detected.")

    click.echo(f"\nMatched: {len(matched)} items (skipped)")
    if rem_only:
        click.echo(f"Reminders only: {len(rem_only)}")
    if tw_only:
        click.echo(f"Taskwarrior only: {len(tw_only)}")
    if metadata_diffs:
        click.echo(f"Metadata drift: {len(metadata_diffs)}")


@click.group()
def cli():
    """Unified task management across Apple Reminders and Taskwarrior."""


@cli.command()
@click.argument("description")
@click.option("--project", default="Inbox", help="Project/list name.")
def add(description, project):
    """Add task to both systems."""
    prefixed = f"{project}: {description}"

    if is_darwin() and has_command("reminders"):
        existing = subprocess.run(
            ["reminders", "show-lists"], capture_output=True, text=True
        )
        if project not in existing.stdout.splitlines():
            run(["reminders", "new-list", project])

        result = run(["reminders", "add", project, prefixed])
        if result.returncode == 0:
            click.echo(f"Reminders ({project}): added")

    if has_command("task"):
        result = run(["task", "add", prefixed, f"project:{project}"])
        if result.returncode == 0:
            click.echo(f"Taskwarrior ({project}): added")


@cli.command()
@click.option("--project", default=None, help="Scope to a specific project/list.")
def drift(project):
    """Show drift between Reminders and Taskwarrior."""
    rem_only, tw_only, matched, metadata_diffs = compute_drift(project)
    print_drift(rem_only, tw_only, matched, metadata_diffs)


@cli.command()
@click.option("--project", default=None, help="Scope to a specific project/list.")
@click.option("--approve", is_flag=True, default=False, help="Skip confirmation prompt.")
def sync(project, approve):
    """Sync missing items to both systems."""
    rem_only, tw_only, matched, metadata_diffs = compute_drift(project)
    print_drift(rem_only, tw_only, matched, metadata_diffs)

    total = len(rem_only) + len(tw_only)
    if total == 0:
        return

    click.echo(
        f"\nWill copy {len(rem_only)} items to Taskwarrior "
        f"and {len(tw_only)} items to Reminders."
    )
    if not approve and not click.confirm("Proceed?"):
        click.echo("Aborted.")
        return

    # Reminders-only → add to Taskwarrior
    for item in rem_only.values():
        proj = item["project"]
        prefixed = f"{proj}: {item['title']}"
        result = run(["task", "add", prefixed, f"project:{proj}"])
        if result.returncode == 0:
            click.echo(f"  + TW: {prefixed}")
            if item["status"] == "completed":
                find = subprocess.run(
                    ["task", f"project.is:{proj}", prefixed, "uuids"],
                    capture_output=True, text=True,
                )
                uuid = find.stdout.strip()
                if uuid:
                    run(["task", uuid, "done"])

    # Taskwarrior-only → add to Reminders
    if is_darwin() and has_command("reminders"):
        existing = subprocess.run(
            ["reminders", "show-lists"], capture_output=True, text=True
        )
        existing_lists = set(existing.stdout.strip().splitlines())

        for item in tw_only.values():
            proj = item["project"]
            prefixed = f"{proj}: {item['title']}"

            if proj not in existing_lists:
                run(["reminders", "new-list", proj])
                existing_lists.add(proj)

            result = run(["reminders", "add", proj, prefixed])
            if result.returncode == 0:
                click.echo(f"  + Reminders: {prefixed}")
                if item["status"] == "completed":
                    show = subprocess.run(
                        ["reminders", "show", proj, "--format", "json"],
                        capture_output=True, text=True,
                    )
                    if show.returncode == 0:
                        try:
                            items = json.loads(show.stdout)
                            for i, r in enumerate(items):
                                if r.get("title", "") == prefixed:
                                    run(["reminders", "complete", proj, str(i)])
                                    break
                        except json.JSONDecodeError:
                            pass

    click.echo("\nDone.")


if __name__ == "__main__":
    cli(prog_name="taskmanager")
