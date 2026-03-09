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
        return {}, {}

    tasks = {}
    # FIXME: track instance counts to skip duplicate-title drift
    # See DuplicateInstances.md for proper multi-instance matching
    instance_counts = {}
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
        instance_counts[key] = instance_counts.get(key, 0) + 1
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
                "end": task.get("end", ""),
                "entry": task.get("entry", ""),
                "annotations": task.get("annotations", []),
                "priority": ""
                if task.get("priority", "") == "none"
                else task.get("priority", ""),
            }
    return tasks, instance_counts


def get_reminders(project_filter=None, include_completed=True):
    """Export reminders as a dict keyed by (list, title)."""
    if not (is_darwin() and has_command("reminders")):
        return {}, {}

    if project_filter:
        lists = [project_filter]
    else:
        result = subprocess.run(
            ["reminders", "show-lists"], capture_output=True, text=True
        )
        if result.returncode != 0:
            return {}, {}
        lists = result.stdout.strip().splitlines()

    reminders = {}
    # FIXME: track instance counts to skip duplicate-title drift
    # See DuplicateInstances.md for proper multi-instance matching
    instance_counts = {}

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
            instance_counts[key] = instance_counts.get(key, 0) + 1
            status = "completed" if is_completed else "pending"
            if key not in reminders:
                reminders[key] = {
                    "project": list_name,
                    "title": title,
                    "status": status,
                    "source": "reminders",
                    "due": item.get("dueDate", ""),
                    "completionDate": item.get("completionDate", ""),
                    "creationDate": item.get("creationDate", ""),
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
    return reminders, instance_counts


REMINDERS_READ_ONLY_FIELDS = {"completed", "created"}

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

    # Completion date — only sync Rem→TW when Rem has strictly older datetime
    if tw["status"] == "completed" and rem["status"] == "completed":
        tw_end = format_date_local(tw.get("end", ""))
        rem_completion = format_date_local(rem.get("completionDate", ""))
        if rem_completion and tw_end and rem_completion < tw_end:
            diffs.append(
                (
                    "completed",
                    rem_completion or "''",
                    tw_end or "''",
                )
            )

    # Creation date — only sync Rem→TW when Rem has strictly older datetime
    tw_entry = format_date_local(tw.get("entry", ""))
    rem_creation = format_date_local(rem.get("creationDate", ""))
    if rem_creation and tw_entry and rem_creation < tw_entry:
        diffs.append(
            (
                "created",
                rem_creation or "''",
                tw_entry or "''",
            )
        )

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
    tw_tasks, tw_counts = get_tw_tasks(project_filter)

    click.echo("Loading Reminders...", err=True)
    reminder_tasks, rem_counts = get_reminders(project_filter)

    # FIXME: skip keys with multiple instances on either side — these are
    # duplicate-title tasks where merged metadata produces false drift.
    # See DuplicateInstances.md for proper multi-instance matching.
    multi_instance = {
        k for k, c in tw_counts.items() if c > 1
    } | {k for k, c in rem_counts.items() if c > 1}

    if multi_instance:
        click.echo(
            f"\nWarning: skipping {len(multi_instance)} duplicate-title"
            " item(s) (rename to make unique):",
            err=True,
        )
        for project, title in sorted(multi_instance):
            tw_n = tw_counts.get((project, title), 0)
            rem_n = rem_counts.get((project, title), 0)
            click.echo(
                f"  {project}: {title} (TW: {tw_n}, Rem: {rem_n})", err=True
            )

    tw_keys = set(tw_tasks.keys()) - multi_instance
    rem_keys = set(reminder_tasks.keys()) - multi_instance

    matched = tw_keys & rem_keys
    tw_only = {k: tw_tasks[k] for k in sorted(tw_keys - rem_keys)}
    rem_only = {k: reminder_tasks[k] for k in sorted(rem_keys - tw_keys)}

    # Fuzzy match: if one title is a substring of the other within the same
    # project, treat as matched with title drift (longer title wins)
    fuzzy_matched = []
    used_tw = set()
    for rk in list(rem_only.keys()):
        for tk in list(tw_only.keys()):
            if tk in used_tw or rk[0] != tk[0]:
                continue
            r_title, t_title = rk[1], tk[1]
            if r_title in t_title or t_title in r_title:
                longer = t_title if len(t_title) >= len(r_title) else r_title
                key = (rk[0], longer)
                fuzzy_matched.append((rk, tk, key))
                used_tw.add(tk)
                break
    for rk, tk, key in fuzzy_matched:
        rem_only.pop(rk, None)
        tw_only.pop(tk, None)
        matched.add(key)
        tw_tasks[key] = tw_tasks.get(tk, tw_tasks.get(key))
        reminder_tasks[key] = reminder_tasks.get(rk, reminder_tasks.get(key))

    metadata_diffs = {}
    for key in sorted(matched):
        tw = tw_tasks.get(key)
        rem = reminder_tasks.get(key)
        if not tw or not rem:
            continue
        diffs = compare_metadata(tw, rem)
        if tw["title"] != rem["title"]:
            diffs.append(("title", rem["title"], tw["title"]))
        if diffs:
            metadata_diffs[key] = {
                "diffs": diffs,
                "tw": tw,
                "rem": rem,
            }

    return rem_only, tw_only, matched, metadata_diffs


def filter_metadata_diffs(metadata_diffs, notes_only=False, direction=None):
    """Filter metadata diffs to specific fields.

    Removes fields that can't be synced to the destination (e.g. completed/created
    are read-only in Reminders via EventKit API).
    """
    filtered = {}
    for key, info in metadata_diffs.items():
        diffs = info["diffs"]
        if notes_only:
            diffs = [d for d in diffs if d[0] == "notes"]
        if direction == "tw":
            diffs = [d for d in diffs if d[0] not in REMINDERS_READ_ONLY_FIELDS]
        kept = []
        for d in diffs:
            field, rem_val, tw_val = d
            if direction is None and field in REMINDERS_READ_ONLY_FIELDS:
                flow = infer_flow(field, rem_val, tw_val)
                if flow == "tw_to_rem":
                    continue
            kept.append(d)
        if kept:
            filtered[key] = {
                "diffs": kept,
                "tw": info["tw"],
                "rem": info["rem"],
            }
    return filtered


def infer_flow(field, rem_val, tw_val):
    """Infer natural sync direction for a field based on which side has data."""
    empty = ("''", "none", "pending")
    if field == "title":
        if len(tw_val) >= len(rem_val):
            return "tw_to_rem"
        return "rem_to_tw"
    if field == "status":
        if rem_val == "completed":
            return "rem_to_tw"
        return "tw_to_rem"
    if field in ("completed", "created"):
        return "rem_to_tw"
    rem_empty = rem_val in empty
    tw_empty = tw_val in empty
    if rem_empty and not tw_empty:
        return "tw_to_rem"
    return "rem_to_tw"


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
            click.echo(f"      {field}: {from_val} \u2192 {to_val}")


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
        for key, info in metadata_diffs.items():
            print_drift_item(key, info, direction=direction)

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


FIELD_DISPLAY_NAMES = {
    "due": "due",
    "end": "completed",
    "entry": "created",
    "notes": "notes",
    "priority": "priority",
    "title": "title",
    "status": "status",
}


def format_update_summary(updates):
    """Format update keys as readable field names with values."""
    parts = []
    for key, val in updates.items():
        name = FIELD_DISPLAY_NAMES.get(key, key)
        display_val = format_date_local(val) if key in ("due", "end", "entry") else val
        parts.append(f"{name}: {display_val}")
    return ", ".join(parts)


def sync_metadata(metadata_diffs, direction=None, interactive=False):
    """Sync metadata for matched items with drift. Returns count of updated items.

    direction: None=both ways, "reminders"=reminders→tw, "tw"=tw→reminders.
    """
    count = 0
    for (project, title), info in metadata_diffs.items():
        diffs = info["diffs"]
        tw = info["tw"]
        rem = info["rem"]
        prefixed = f"{project}: {title}"

        if interactive:
            click.echo("")
            print_drift_item((project, title), info, direction=direction)
            if not click.confirm("  Sync?"):
                continue

        tw_updates = {}
        rem_updates = {}

        for field, rem_val, tw_val in diffs:
            if direction == "reminders":
                flow = "rem_to_tw"
            elif direction == "tw":
                flow = "tw_to_rem"
            else:
                flow = infer_flow(field, rem_val, tw_val)

            if field == "title":
                longer = tw_val if len(tw_val) >= len(rem_val) else rem_val
                longer_prefixed = f"{project}: {longer}"
                if flow == "rem_to_tw":
                    tw_updates["title"] = longer_prefixed
                elif flow == "tw_to_rem":
                    rem_updates["title"] = longer_prefixed
            elif field == "due":
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
            elif field == "completed":
                if flow == "rem_to_tw":
                    raw = rem.get("completionDate", "")
                    if raw:
                        tw_updates["end"] = raw
                elif flow == "tw_to_rem":
                    pass
            elif field == "created":
                if flow == "rem_to_tw":
                    raw = rem.get("creationDate", "")
                    if raw:
                        tw_updates["entry"] = raw
                elif flow == "tw_to_rem":
                    pass
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
            tw_prefixed = f"{project}: {tw['title']}"
            uuids = find_tw_uuids(project, tw_prefixed)
            for uuid in uuids:
                modify_args = []
                if "title" in tw_updates:
                    modify_args.append(f"description:{tw_updates['title']}")
                if "due" in tw_updates:
                    modify_args.append(f"due:{tw_updates['due']}")
                if "end" in tw_updates:
                    modify_args.append(f"end:{tw_updates['end']}")
                if "entry" in tw_updates:
                    modify_args.append(f"entry:{tw_updates['entry']}")
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
                    f"  ~ Taskwarrior: {prefixed}\n    {format_update_summary(tw_updates)}"
                )

        if rem_updates and is_darwin() and has_command("reminders"):
            rem_prefixed = f"{project}: {rem['title']}"
            idx = find_reminder_index(project, rem_prefixed)
            if idx is not None:
                edit_args = [
                    "reminders",
                    "edit",
                    project,
                    str(idx),
                    "--include-completed",
                ]
                if "title" in rem_updates:
                    edit_args.append(rem_updates["title"])
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
                        complete_cmd = ["reminders", "complete", project, str(idx)]
                        raw_end = tw.get("end", "")
                        if raw_end:
                            complete_cmd.extend(["--completion-date", tw_date_to_iso(raw_end)])
                        run(complete_cmd)
                    else:
                        cidx = find_reminder_index(
                            project, rem_prefixed, completed_only=True
                        )
                        if cidx is not None:
                            run(["reminders", "uncomplete", project, str(cidx)])
                count += 1
                click.echo(
                    f"  ~ Reminders: {prefixed}\n    {format_update_summary(rem_updates)}"
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
    if name in ("t", "tw", "taskwarrior"):
        return "tw"
    if name in ("r", "rem", "rems", "reminders"):
        return "reminders"
    return name


def parse_projects(project_str):
    """Parse comma-separated project string into list."""
    if not project_str:
        return [None]
    return [p.strip() for p in project_str.split(",") if p.strip()]


def filter_by_title(rem_only, tw_only, metadata_diffs, title_filter):
    """Filter drift results to items matching title substring."""
    if not title_filter:
        return rem_only, tw_only, metadata_diffs
    rem_only = {k: v for k, v in rem_only.items() if title_filter.lower() in k[1].lower()}
    tw_only = {k: v for k, v in tw_only.items() if title_filter.lower() in k[1].lower()}
    metadata_diffs = {
        k: v for k, v in metadata_diffs.items() if title_filter.lower() in k[1].lower()
    }
    return rem_only, tw_only, metadata_diffs


@cli.command()
@click.option("--project", default=None, help="Scope to a single project/list.")
@click.option(
    "--projects", default=None, help="Comma-separated project/list names."
)
@click.option("--filter", default=None, help="Filter to items matching title substring.")
@click.option(
    "--notes", is_flag=True, default=False, help="Show only notes/annotations drift."
)
@click.option(
    "--source",
    default=None,
    help="Source system (t/tw/taskwarrior, r/rem/rems/reminders).",
)
@click.option(
    "--destination",
    default=None,
    help="Destination system (t/tw/taskwarrior, r/rem/rems/reminders).",
)
def drift(project, projects, filter, notes, source, destination):
    """Show drift between Reminders and Taskwarrior."""
    source = normalize_system_name(source) if source else None
    destination = normalize_system_name(destination) if destination else None

    if (source is None) != (destination is None):
        click.echo("Error: --source and --destination must be used together", err=True)
        raise SystemExit(1)
    if source and source == destination:
        click.echo("Error: --source and --destination must be different", err=True)
        raise SystemExit(1)

    project_list = parse_projects(projects) if projects else [project]
    all_rem_only, all_tw_only, all_matched, all_metadata_diffs = {}, {}, set(), {}
    for proj in project_list:
        rem_only, tw_only, matched, metadata_diffs = compute_drift(proj)
        all_rem_only.update(rem_only)
        all_tw_only.update(tw_only)
        all_matched.update(matched)
        all_metadata_diffs.update(metadata_diffs)

    all_metadata_diffs = filter_metadata_diffs(
        all_metadata_diffs, notes_only=notes, direction=source
    )
    if notes:
        all_rem_only, all_tw_only = {}, {}

    if source == "reminders":
        all_tw_only = {}
    elif source == "tw":
        all_rem_only = {}

    all_rem_only, all_tw_only, all_metadata_diffs = filter_by_title(
        all_rem_only, all_tw_only, all_metadata_diffs, filter
    )

    print_drift(
        all_rem_only, all_tw_only, all_matched, all_metadata_diffs, direction=source
    )


@cli.command()
@click.option("--project", default=None, help="Scope to a single project/list.")
@click.option(
    "--projects", default=None, help="Comma-separated project/list names."
)
@click.option("--filter", default=None, help="Filter to items matching title substring.")
@click.option(
    "--approve", is_flag=True, default=False, help="Skip confirmation prompt."
)
@click.option(
    "--interactive", is_flag=True, default=False, help="Confirm each item individually."
)
@click.option(
    "--notes", is_flag=True, default=False, help="Sync only notes/annotations."
)
@click.option(
    "--source",
    default=None,
    help="Source system (t/tw/taskwarrior, r/rem/rems/reminders).",
)
@click.option(
    "--destination",
    default=None,
    help="Destination system (t/tw/taskwarrior, r/rem/rems/reminders).",
)
def sync(project, projects, filter, approve, interactive, notes, source, destination):
    """Sync missing items to both systems."""
    if not project and not projects and not interactive:
        click.echo(
            "Error: --project, --projects, or --interactive is required"
            " to avoid accidental bulk changes.",
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

    project_list = parse_projects(projects) if projects else [project]
    all_rem_only, all_tw_only, all_matched, all_metadata_diffs = {}, {}, set(), {}
    for proj in project_list:
        rem_only, tw_only, matched, metadata_diffs = compute_drift(proj)
        all_rem_only.update(rem_only)
        all_tw_only.update(tw_only)
        all_matched.update(matched)
        all_metadata_diffs.update(metadata_diffs)

    rem_only, tw_only, matched = all_rem_only, all_tw_only, all_matched
    metadata_diffs = filter_metadata_diffs(
        all_metadata_diffs, notes_only=notes, direction=source
    )
    if notes:
        rem_only, tw_only = {}, {}

    # Filter buckets based on direction
    if source == "reminders":
        tw_only = {}
    elif source == "tw":
        rem_only = {}

    rem_only, tw_only, metadata_diffs = filter_by_title(
        rem_only, tw_only, metadata_diffs, filter
    )

    if not interactive:
        print_drift(rem_only, tw_only, matched, metadata_diffs, direction=source)

    total = len(rem_only) + len(tw_only) + len(metadata_diffs)
    if total == 0:
        if interactive:
            click.echo("\nNo drift detected.")
        return

    if not interactive:
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
        if interactive:
            click.echo(f"\nReminders only:")
            click.echo(f"  {proj}: {item['title']}")
            click.echo(f"    status: {item['status']}")
            rem_due = format_date_local(item.get("due", ""))
            if rem_due:
                click.echo(f"    due: {rem_due}")
            rem_notes = (item.get("notes") or "").strip()
            if rem_notes:
                click.echo(f"    notes: {repr(rem_notes)}")
            rem_prio = REMINDERS_PRIORITY_MAP.get(item.get("priority", 0), "")
            if rem_prio:
                click.echo(f"    priority: {PRIORITY_LABEL.get(rem_prio, rem_prio)}")
            if not click.confirm("  Copy to Taskwarrior?"):
                continue
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

            find = subprocess.run(
                ["task", f"project.is:{proj}", prefixed, "uuids"],
                capture_output=True,
                text=True,
            )
            uuid = find.stdout.strip()
            if uuid:
                # Notes → annotation
                item_notes = (item.get("notes") or "").strip()
                if item_notes:
                    run(["task", uuid, "annotate", item_notes])

                # Creation date
                raw_created = item.get("creationDate", "")
                if raw_created:
                    run(["task", uuid, "modify", f"entry:{raw_created}"])

                # Completion date + status
                if item["status"] == "completed":
                    run(["task", uuid, "done"])
                    raw_end = item.get("completionDate", "")
                    if raw_end:
                        run(["task", uuid, "modify", f"end:{raw_end}"])

    # Taskwarrior-only → add to Reminders
    if is_darwin() and has_command("reminders"):
        existing = subprocess.run(
            ["reminders", "show-lists"], capture_output=True, text=True
        )
        existing_lists = set(existing.stdout.strip().splitlines())

        for item in tw_only.values():
            proj = item["project"]
            prefixed = f"{proj}: {item['title']}"

            if interactive:
                click.echo(f"\nTaskwarrior only:")
                click.echo(f"  {proj}: {item['title']}")
                click.echo(f"    status: {item['status']}")
                tw_due = format_date_local(item.get("due", ""))
                if tw_due:
                    click.echo(f"    due: {tw_due}")
                tw_anns = item.get("annotations", [])
                if tw_anns:
                    tw_notes = "; ".join(a.get("description", "") for a in tw_anns)
                    click.echo(f"    notes: {repr(tw_notes)}")
                tw_prio = item.get("priority", "")
                if tw_prio:
                    click.echo(f"    priority: {PRIORITY_LABEL.get(tw_prio, tw_prio)}")
                if not click.confirm("  Copy to Reminders?"):
                    continue

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
                                    complete_cmd = ["reminders", "complete", proj, str(i)]
                                    raw_end = item.get("end", "")
                                    if raw_end:
                                        complete_cmd.extend(["--completion-date", tw_date_to_iso(raw_end)])
                                    run(complete_cmd)
                                    break
                        except json.JSONDecodeError:
                            pass

    # Sync metadata for matched items with drift
    if metadata_diffs:
        meta_count = sync_metadata(metadata_diffs, direction=source, interactive=interactive)
        if meta_count:
            click.echo(f"\nUpdated metadata on {meta_count} items.")

    click.echo("\nDone.")


if __name__ == "__main__":
    cli(prog_name="taskmanager")
