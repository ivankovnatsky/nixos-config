#!/usr/bin/env python3
"""Taskmanager: unified task management across Apple Reminders and Taskwarrior."""

import json
import platform
import shutil
import subprocess

import click


def has_command(cmd):
    return shutil.which(cmd) is not None


def is_darwin():
    return platform.system() == "Darwin"


def run(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        click.echo(f"Error running {' '.join(cmd)}: {result.stderr.strip()}", err=True)
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
            title = desc[len(prefix) :]
        else:
            title = desc

        key = (project, title)
        if key in tasks:
            # Merge: combine annotations, prefer pending item's metadata
            existing = tasks[key]
            seen = {a.get("description", "") for a in existing["annotations"]}
            for ann in task.get("annotations", []):
                if ann.get("description", "") not in seen:
                    existing["annotations"].append(ann)
                    seen.add(ann.get("description", ""))
            # Pending item wins over completed for status/due
            if status == "pending" and existing["status"] != "pending":
                existing["status"] = status
                existing["due"] = task.get("due", "")
            elif not existing["due"] and task.get("due", ""):
                existing["due"] = task["due"]
            raw_prio = task.get("priority", "")
            if not existing["priority"] and raw_prio and raw_prio != "none":
                existing["priority"] = raw_prio
        else:
            tasks[key] = {
                "project": project,
                "title": title,
                "status": status,
                "source": "taskwarrior",
                "due": task.get("due", ""),
                "annotations": task.get("annotations", []),
                "priority": ""
                if task.get("priority", "") == "none"
                else task.get("priority", ""),
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
                title = title[len(prefix) :]

            key = (list_name, title)
            status = "completed" if is_completed else "pending"
            if key not in reminders:
                reminders[key] = {
                    "project": list_name,
                    "title": title,
                    "status": status,
                    "source": "reminders",
                    "due": item.get("dueDate", ""),
                    "notes": item.get("notes", ""),
                    "priority": item.get("priority", 0),
                }
            else:
                existing = reminders[key]
                # Pending item wins over completed for status/due
                if status == "pending" and existing["status"] != "pending":
                    existing["status"] = status
                    existing["due"] = item.get("dueDate", "")
                elif not existing["due"] and item.get("dueDate", ""):
                    existing["due"] = item["dueDate"]
                if not existing["notes"] and item.get("notes", ""):
                    existing["notes"] = item["notes"]
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
    """Convert TW compact date (20260319T220000Z) to ISO 8601 UTC."""
    if not tw_date or len(tw_date) < 16:
        return tw_date
    return (
        f"{tw_date[:4]}-{tw_date[4:6]}-{tw_date[6:8]}"
        f"T{tw_date[9:11]}:{tw_date[11:13]}:{tw_date[13:15]}Z"
    )


def tw_date_to_local_iso(tw_date):
    """Convert TW compact UTC date (20260319T220000Z) to local ISO 8601."""
    if not tw_date or len(tw_date) < 16:
        return tw_date
    from datetime import datetime

    utc_dt = datetime.fromisoformat(tw_date_to_iso(tw_date))
    return utc_dt.astimezone().strftime("%Y-%m-%dT%H:%M:%S")


def is_tw_compact(date_str):
    """Check if date string is TW compact format (YYYYMMDDTHHMMSSZ)."""
    return (
        len(date_str) == 16
        and date_str[8] == "T"
        and date_str[15] == "Z"
        and date_str[:8].isdigit()
        and date_str[9:15].isdigit()
    )


def format_date_local(date_str):
    """Format a date string to local YYYY-MM-DDTHH:MM:SS, converting UTC if needed."""
    if not date_str:
        return ""
    from datetime import datetime

    if is_tw_compact(date_str):
        return tw_date_to_local_iso(date_str)
    try:
        dt = datetime.fromisoformat(date_str)
        if dt.tzinfo is not None:
            return dt.astimezone().strftime("%Y-%m-%dT%H:%M:%S")
        return dt.strftime("%Y-%m-%dT%H:%M:%S")
    except ValueError:
        pass
    return date_str


def compare_metadata(tw, rem):
    """Compare metadata fields between matched TW and Reminders items.

    Returns list of (field, rem_val, tw_val) tuples with display-ready values.
    """
    diffs = []

    # Status
    if tw["status"] != rem["status"]:
        diffs.append(("status", rem["status"], tw["status"]))

    # Due date — compare in local time to avoid UTC midnight shifts
    tw_due_display = format_date_local(tw.get("due", ""))
    rem_due_display = format_date_local(rem.get("due", ""))
    if tw_due_display != rem_due_display:
        diffs.append(
            (
                "due",
                rem_due_display or "''",
                tw_due_display or "''",
            )
        )

    # Notes vs annotations
    rem_notes = (rem.get("notes") or "").strip()
    tw_annotations = tw.get("annotations", [])
    tw_ann_texts = [a.get("description", "") for a in tw_annotations]
    tw_notes_display = repr("; ".join(tw_ann_texts)) if tw_ann_texts else "''"
    rem_notes_display = repr(rem_notes) if rem_notes else "''"
    if rem_notes and not any(rem_notes in text for text in tw_ann_texts):
        diffs.append(("notes", rem_notes_display, tw_notes_display))
    elif not rem_notes and tw_ann_texts:
        diffs.append(("notes", rem_notes_display, tw_notes_display))

    # Priority
    rem_prio = REMINDERS_PRIORITY_MAP.get(rem.get("priority", 0), "")
    tw_prio = tw.get("priority", "")
    if rem_prio != tw_prio:
        diffs.append(
            (
                "priority",
                PRIORITY_LABEL.get(rem_prio, rem_prio) or "''",
                PRIORITY_LABEL.get(tw_prio, tw_prio) or "''",
            )
        )

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


def infer_flow(field, rem_val, tw_val):
    """Infer natural sync direction for a field based on which side has data."""
    empty = ("''", "none", "pending")
    if field == "status":
        if rem_val == "completed":
            return "rem_to_tw"
        return "tw_to_rem"
    rem_empty = rem_val in empty
    tw_empty = tw_val in empty
    if rem_empty and not tw_empty:
        return "tw_to_rem"
    return "rem_to_tw"


def print_drift(rem_only, tw_only, matched, metadata_diffs, direction=None):
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
                    click.echo(f"      {field}: {from_val} \u2192 {to_val}")

    if not rem_only and not tw_only and not metadata_diffs:
        click.echo("\nNo drift detected.")

    click.echo(f"\nMatched: {len(matched)} items (skipped)")
    if rem_only:
        click.echo(f"Reminders only: {len(rem_only)}")
    if tw_only:
        click.echo(f"Taskwarrior only: {len(tw_only)}")
    if metadata_diffs:
        click.echo(f"Metadata drift: {len(metadata_diffs)}")


def find_tw_uuids(project, prefixed_title):
    """Find all TW task UUIDs matching project and prefixed description."""
    result = subprocess.run(
        ["task", f"project.is:{project}", "export"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return []
    uuids = []
    try:
        for t in json.loads(result.stdout):
            if t.get("description", "") == prefixed_title:
                uuids.append(t["uuid"])
    except json.JSONDecodeError:
        pass
    return uuids


def find_reminder_index(list_name, prefixed_title, completed_only=False):
    """Find reminder index by list and prefixed title."""
    cmd = ["reminders", "show", list_name, "--format", "json"]
    if completed_only:
        cmd.append("--only-completed")
    else:
        cmd.append("--include-completed")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return None
    try:
        for i, item in enumerate(json.loads(result.stdout)):
            if item.get("title", "") == prefixed_title:
                return i
    except json.JSONDecodeError:
        pass
    return None


def sync_metadata(metadata_diffs, direction=None):
    """Sync metadata for matched items with drift. Returns count of updated items.

    direction: None=both ways, "reminders"=reminders→tw, "tw"=tw→reminders.
    """
    count = 0
    for (project, title), info in metadata_diffs.items():
        diffs = info["diffs"]
        tw = info["tw"]
        rem = info["rem"]
        prefixed = f"{project}: {title}"

        tw_updates = {}
        rem_updates = {}

        for field, rem_val, tw_val in diffs:
            if direction == "reminders":
                flow = "rem_to_tw"
            elif direction == "tw":
                flow = "tw_to_rem"
            else:
                flow = infer_flow(field, rem_val, tw_val)

            if field == "due":
                if flow == "rem_to_tw":
                    tw_updates["due"] = rem.get("due", "")
                elif flow == "tw_to_rem":
                    raw_due = tw.get("due", "")
                    rem_updates["due"] = (
                        tw_date_to_local_iso(raw_due) if raw_due else ""
                    )
            elif field == "notes":
                if flow == "rem_to_tw":
                    tw_updates["notes"] = (rem.get("notes") or "").strip()
                elif flow == "tw_to_rem":
                    ann_texts = [
                        a.get("description", "") for a in tw.get("annotations", [])
                    ]
                    rem_updates["notes"] = "\n".join(ann_texts)
            elif field == "priority":
                if flow == "rem_to_tw":
                    prio = REMINDERS_PRIORITY_MAP.get(rem.get("priority", 0), "")
                    if prio:
                        tw_updates["priority"] = prio
                elif flow == "tw_to_rem":
                    tw_prio = tw.get("priority", "")
                    rem_prio_label = TW_TO_REMINDERS_PRIORITY.get(tw_prio)
                    if rem_prio_label:
                        rem_updates["priority"] = rem_prio_label
            elif field == "status":
                if flow == "rem_to_tw":
                    if rem["status"] == "completed":
                        tw_updates["status"] = "completed"
                    else:
                        tw_updates["status"] = "pending"
                elif flow == "tw_to_rem":
                    if tw["status"] == "completed":
                        rem_updates["status"] = "completed"
                    else:
                        rem_updates["status"] = "pending"

        if tw_updates:
            uuids = find_tw_uuids(project, prefixed)
            for uuid in uuids:
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
                    if tw_updates["status"] == "completed":
                        run(["task", uuid, "done"])
                    else:
                        run(["task", uuid, "modify", "status:pending"])
            if uuids:
                count += 1
                click.echo(
                    f"  ~ Taskwarrior: {prefixed} ({', '.join(tw_updates.keys())})"
                )

        if rem_updates and is_darwin() and has_command("reminders"):
            idx = find_reminder_index(project, prefixed)
            if idx is not None:
                edit_args = [
                    "reminders",
                    "edit",
                    project,
                    str(idx),
                    "--include-completed",
                ]
                if "notes" in rem_updates:
                    edit_args.extend(["--notes", rem_updates["notes"]])
                if "due" in rem_updates:
                    edit_args.extend(["--due-date", rem_updates["due"]])
                if "priority" in rem_updates:
                    edit_args.extend(["--priority", rem_updates["priority"]])
                if len(edit_args) > 5:
                    run(edit_args)
                if "status" in rem_updates:
                    if rem_updates["status"] == "completed":
                        run(["reminders", "complete", project, str(idx)])
                    else:
                        cidx = find_reminder_index(
                            project, prefixed, completed_only=True
                        )
                        if cidx is not None:
                            run(["reminders", "uncomplete", project, str(cidx)])
                count += 1
                click.echo(
                    f"  ~ Reminders: {prefixed} ({', '.join(rem_updates.keys())})"
                )

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


def normalize_system_name(name):
    """Normalize system name to internal form."""
    if name == "taskwarrior":
        return "tw"
    return name


@cli.command()
@click.option("--project", default=None, help="Scope to a specific project/list.")
@click.option(
    "--notes", is_flag=True, default=False, help="Show only notes/annotations drift."
)
@click.option(
    "--source",
    type=click.Choice(["taskwarrior", "reminders"]),
    default=None,
    help="Source system to sync from.",
)
@click.option(
    "--destination",
    type=click.Choice(["taskwarrior", "reminders"]),
    default=None,
    help="Destination system to sync to.",
)
def drift(project, notes, source, destination):
    """Show drift between Reminders and Taskwarrior."""
    source = normalize_system_name(source) if source else None
    destination = normalize_system_name(destination) if destination else None

    if (source is None) != (destination is None):
        click.echo("Error: --source and --destination must be used together", err=True)
        raise SystemExit(1)
    if source and source == destination:
        click.echo("Error: --source and --destination must be different", err=True)
        raise SystemExit(1)

    rem_only, tw_only, matched, metadata_diffs = compute_drift(project)
    metadata_diffs = filter_metadata_diffs(metadata_diffs, notes_only=notes)
    if notes:
        rem_only, tw_only = {}, {}

    if source == "reminders":
        tw_only = {}
    elif source == "tw":
        rem_only = {}

    print_drift(rem_only, tw_only, matched, metadata_diffs, direction=source)


@cli.command()
@click.option("--project", default=None, help="Scope to a specific project/list.")
@click.option(
    "--approve", is_flag=True, default=False, help="Skip confirmation prompt."
)
@click.option(
    "--notes", is_flag=True, default=False, help="Sync only notes/annotations."
)
@click.option(
    "--source",
    type=click.Choice(["taskwarrior", "reminders"]),
    default=None,
    help="Source system to sync from.",
)
@click.option(
    "--destination",
    type=click.Choice(["taskwarrior", "reminders"]),
    default=None,
    help="Destination system to sync to.",
)
def sync(project, approve, notes, source, destination):
    """Sync missing items to both systems."""
    click.echo(
        "Error: sync is disabled until taskmanager is battle-tested. "
        "Use 'taskmanager drift' to review differences instead.",
        err=True,
    )
    raise SystemExit(1)
    source = normalize_system_name(source) if source else None
    destination = normalize_system_name(destination) if destination else None

    if (source is None) != (destination is None):
        click.echo("Error: --source and --destination must be used together", err=True)
        raise SystemExit(1)
    if source and source == destination:
        click.echo("Error: --source and --destination must be different", err=True)
        raise SystemExit(1)

    rem_only, tw_only, matched, metadata_diffs = compute_drift(project)
    metadata_diffs = filter_metadata_diffs(metadata_diffs, notes_only=notes)
    if notes:
        rem_only, tw_only = {}, {}

    # Filter buckets based on direction
    if source == "reminders":
        tw_only = {}
    elif source == "tw":
        rem_only = {}

    print_drift(rem_only, tw_only, matched, metadata_diffs, direction=source)

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
            click.echo(f"  + Taskwarrior: {prefixed}")

            # Notes → annotation
            notes = (item.get("notes") or "").strip()
            if notes:
                find = subprocess.run(
                    ["task", f"project.is:{proj}", prefixed, "uuids"],
                    capture_output=True,
                    text=True,
                )
                uuid = find.stdout.strip()
                if uuid:
                    run(["task", uuid, "annotate", notes])

            if item["status"] == "completed":
                find = subprocess.run(
                    ["task", f"project.is:{proj}", prefixed, "uuids"],
                    capture_output=True,
                    text=True,
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
                        capture_output=True,
                        text=True,
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
        meta_count = sync_metadata(metadata_diffs, direction=source)
        if meta_count:
            click.echo(f"\nUpdated metadata on {meta_count} items.")

    click.echo("\nDone.")


if __name__ == "__main__":
    cli(prog_name="taskmanager")
