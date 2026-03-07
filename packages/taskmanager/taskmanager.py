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
TW_TO_REMINDERS_PRIORITY = {"H": "high", "M": "medium", "L": "low"}
PRIORITY_LABEL = {"H": "high", "M": "medium", "L": "low", "": "none"}


def normalize_date(date_str):
    """Normalize date to compact form for comparison (strip punctuation)."""
    if not date_str:
        return ""
    return date_str.replace("-", "").replace(":", "")


def format_date(date_str):
    """Format date for display as YYYY-MM-DD."""
    if not date_str:
        return ""
    clean = normalize_date(date_str)
    if len(clean) >= 8:
        d = clean[:8]
        return f"{d[:4]}-{d[4:6]}-{d[6:8]}"
    return date_str


def tw_date_to_iso(tw_date):
    """Convert TW compact date (20260319T220000Z) to ISO 8601."""
    if not tw_date or len(tw_date) < 16:
        return tw_date
    return (f"{tw_date[:4]}-{tw_date[4:6]}-{tw_date[6:8]}"
            f"T{tw_date[9:11]}:{tw_date[11:13]}:{tw_date[13:15]}Z")


def compare_metadata(tw, rem):
    """Compare metadata fields between matched TW and Reminders items."""
    diffs = []

    # Status
    if tw["status"] != rem["status"]:
        diffs.append(("status", rem["status"], tw["status"]))

    # Due date — compare full timestamps, display as YYYY-MM-DD
    tw_due = normalize_date(tw.get("due", ""))
    rem_due = normalize_date(rem.get("due", ""))
    if tw_due != rem_due:
        diffs.append(("due", format_date(rem.get("due", "")) or "none",
                       format_date(tw.get("due", "")) or "none"))

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
            metadata_diffs[key] = {
                "diffs": diffs,
                "tw": tw_tasks[key],
                "rem": reminder_tasks[key],
            }

    return rem_only, tw_only, matched, metadata_diffs


def filter_metadata_diffs(metadata_diffs, notes_only=False):
    """Filter metadata diffs to specific fields."""
    if not notes_only:
        return metadata_diffs
    filtered = {}
    for key, info in metadata_diffs.items():
        notes_diffs = [d for d in info["diffs"] if d[0] == "notes"]
        if notes_diffs:
            filtered[key] = {
                "diffs": notes_diffs,
                "tw": info["tw"],
                "rem": info["rem"],
            }
    return filtered


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
        for (project, title), info in metadata_diffs.items():
            click.echo(f"  {project}: {title}")
            for field, rem_val, tw_val in info["diffs"]:
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


def find_tw_uuid(project, prefixed_title):
    """Find TW task UUID by project and prefixed description."""
    result = subprocess.run(
        ["task", f"project.is:{project}", "export"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return None
    try:
        for t in json.loads(result.stdout):
            if t.get("description", "") == prefixed_title:
                return t["uuid"]
    except json.JSONDecodeError:
        pass
    return None


def find_reminder_index(list_name, prefixed_title):
    """Find reminder index by list and prefixed title."""
    result = subprocess.run(
        ["reminders", "show", list_name, "--format", "json", "--include-completed"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return None
    try:
        for i, item in enumerate(json.loads(result.stdout)):
            if item.get("title", "") == prefixed_title:
                return i
    except json.JSONDecodeError:
        pass
    return None


def sync_metadata(metadata_diffs):
    """Sync metadata for matched items with drift. Returns count of updated items."""
    count = 0
    for (project, title), info in metadata_diffs.items():
        diffs = info["diffs"]
        tw = info["tw"]
        rem = info["rem"]
        prefixed = f"{project}: {title}"

        tw_updates = {}
        rem_updates = {}

        for field, rem_val, tw_val in diffs:
            if field == "due":
                if rem_val != "none" and tw_val == "none":
                    tw_updates["due"] = rem.get("due", "")
                elif tw_val != "none" and rem_val == "none":
                    # reminders edit doesn't support --due-date, skip
                    pass
            elif field == "notes":
                if "not in annotations" in str(tw_val):
                    tw_updates["notes"] = (rem.get("notes") or "").strip()
                elif rem_val == "none" and tw.get("annotations"):
                    ann_texts = [a.get("description", "") for a in tw["annotations"]]
                    rem_updates["notes"] = "\n".join(ann_texts)
            elif field == "priority":
                if rem_val != "none" and tw_val == "none":
                    prio = REMINDERS_PRIORITY_MAP.get(rem.get("priority", 0), "")
                    if prio:
                        tw_updates["priority"] = prio
                # reminders edit doesn't support --priority, skip
            elif field == "status":
                if rem_val == "completed" and tw_val == "pending":
                    tw_updates["status"] = "completed"
                elif tw_val == "completed" and rem_val == "pending":
                    rem_updates["status"] = "completed"

        if tw_updates:
            uuid = find_tw_uuid(project, prefixed)
            if uuid:
                modify_args = []
                if "due" in tw_updates:
                    modify_args.append(f"due:{tw_updates['due']}")
                if "priority" in tw_updates:
                    modify_args.append(f"priority:{tw_updates['priority']}")
                if modify_args:
                    run(["task", uuid, "modify"] + modify_args)
                if "notes" in tw_updates:
                    run(["task", uuid, "annotate", tw_updates["notes"]])
                if "status" in tw_updates:
                    run(["task", uuid, "done"])
                count += 1
                click.echo(f"  ~ TW: {prefixed} ({', '.join(tw_updates.keys())})")

        if rem_updates and is_darwin() and has_command("reminders"):
            idx = find_reminder_index(project, prefixed)
            if idx is not None:
                if "notes" in rem_updates:
                    run(["reminders", "edit", project, str(idx),
                         "--include-completed", "--notes", rem_updates["notes"]])
                if "status" in rem_updates:
                    run(["reminders", "complete", project, str(idx)])
                count += 1
                click.echo(f"  ~ Reminders: {prefixed} ({', '.join(rem_updates.keys())})")

    return count


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
@click.option("--notes", is_flag=True, default=False, help="Show only notes/annotations drift.")
def drift(project, notes):
    """Show drift between Reminders and Taskwarrior."""
    rem_only, tw_only, matched, metadata_diffs = compute_drift(project)
    metadata_diffs = filter_metadata_diffs(metadata_diffs, notes_only=notes)
    if notes:
        rem_only, tw_only = {}, {}
    print_drift(rem_only, tw_only, matched, metadata_diffs)


@cli.command()
@click.option("--project", default=None, help="Scope to a specific project/list.")
@click.option("--approve", is_flag=True, default=False, help="Skip confirmation prompt.")
@click.option("--notes", is_flag=True, default=False, help="Sync only notes/annotations.")
def sync(project, approve, notes):
    """Sync missing items to both systems."""
    rem_only, tw_only, matched, metadata_diffs = compute_drift(project)
    metadata_diffs = filter_metadata_diffs(metadata_diffs, notes_only=notes)
    if notes:
        rem_only, tw_only = {}, {}
    print_drift(rem_only, tw_only, matched, metadata_diffs)

    total = len(rem_only) + len(tw_only) + len(metadata_diffs)
    if total == 0:
        return

    parts = []
    if rem_only:
        parts.append(f"{len(rem_only)} items to Taskwarrior")
    if tw_only:
        parts.append(f"{len(tw_only)} items to Reminders")
    if metadata_diffs:
        parts.append(f"{len(metadata_diffs)} metadata updates")
    click.echo(f"\nWill sync: {', '.join(parts)}.")
    if not approve and not click.confirm("Proceed?"):
        click.echo("Aborted.")
        return

    # Reminders-only → add to Taskwarrior
    for item in rem_only.values():
        proj = item["project"]
        prefixed = f"{proj}: {item['title']}"
        add_cmd = ["task", "add", prefixed, f"project:{proj}"]

        # Due date — pass raw ISO date so TW handles timezone correctly
        raw_due = item.get("due", "")
        if raw_due:
            add_cmd.append(f"due:{raw_due}")

        # Priority
        tw_prio = REMINDERS_PRIORITY_MAP.get(item.get("priority", 0), "")
        if tw_prio:
            add_cmd.append(f"priority:{tw_prio}")

        result = run(add_cmd)
        if result.returncode == 0:
            click.echo(f"  + TW: {prefixed}")

            # Notes → annotation
            notes = (item.get("notes") or "").strip()
            if notes:
                find = subprocess.run(
                    ["task", f"project.is:{proj}", prefixed, "uuids"],
                    capture_output=True, text=True,
                )
                uuid = find.stdout.strip()
                if uuid:
                    run(["task", uuid, "annotate", notes])

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

            add_cmd = ["reminders", "add", proj, prefixed]

            # Due date — convert TW compact format to ISO for reminders CLI
            raw_due = item.get("due", "")
            if raw_due:
                add_cmd.extend(["--due-date", tw_date_to_iso(raw_due)])

            # Priority
            tw_prio = item.get("priority", "")
            rem_prio_label = TW_TO_REMINDERS_PRIORITY.get(tw_prio)
            if rem_prio_label:
                add_cmd.extend(["--priority", rem_prio_label])

            # Notes from annotations
            annotations = item.get("annotations", [])
            if annotations:
                notes_text = "\n".join(a.get("description", "") for a in annotations)
                add_cmd.extend(["--notes", notes_text])

            result = run(add_cmd)
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

    # Sync metadata for matched items with drift
    if metadata_diffs:
        meta_count = sync_metadata(metadata_diffs)
        if meta_count:
            click.echo(f"\nUpdated metadata on {meta_count} items.")

    click.echo("\nDone.")


if __name__ == "__main__":
    cli(prog_name="taskmanager")
