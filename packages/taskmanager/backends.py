"""Data access layer for Taskwarrior and Apple Reminders."""

import json
import subprocess


from utils import (
    has_command,
    is_darwin,
)


def get_tw_tasks(project_filter=None):
    """Export tasks from Taskwarrior as a dict keyed by (project, title).

    Returns (tasks, instance_counts, all_instances) where all_instances is a
    dict of (project, title) -> [list of item dicts] for multi-instance matching.
    """
    cmd = ["task"]
    if project_filter:
        cmd.append(f"project.is:{project_filter}")
    cmd.append("export")

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return {}, {}, {}

    tasks = {}
    instance_counts = {}
    all_instances = {}
    try:
        tw_data = json.loads(result.stdout)
    except json.JSONDecodeError:
        import click

        click.echo("Error: failed to parse Taskwarrior export JSON", err=True)
        raise SystemExit(1)
    for task in tw_data:
        project = task.get("project", "")
        desc = task.get("description", "")
        status = task.get("status", "pending")

        # Skip recurring parent templates
        if status == "recurring":
            continue

        # Normalize "waiting" to "pending" — Reminders has no waiting concept
        if status == "waiting":
            status = "pending"

        # Strip project prefix from description if present
        prefix = f"{project}: "
        if desc.startswith(prefix):
            title = desc[len(prefix) :]
        else:
            title = desc

        key = (project, title)
        instance_counts[key] = instance_counts.get(key, 0) + 1

        item = {
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
            "uuid": task.get("uuid", ""),
            "recur": task.get("recur", ""),
        }

        instance_copy = dict(item)
        instance_copy["annotations"] = list(item["annotations"])
        all_instances.setdefault(key, []).append(instance_copy)

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
            tasks[key] = item
    return tasks, instance_counts, all_instances


def get_reminders(project_filter=None, include_completed=True):
    """Export reminders as a dict keyed by (list, title).

    Returns (reminders, instance_counts, all_instances) where all_instances is a
    dict of (list, title) -> [list of item dicts] for multi-instance matching.
    """
    if not (is_darwin() and has_command("rems")):
        return {}, {}, {}

    if project_filter:
        lists = [project_filter]
    else:
        result = subprocess.run(["rems", "lists"], capture_output=True, text=True)
        if result.returncode != 0:
            return {}, {}, {}
        lists = result.stdout.strip().splitlines()

    reminders = {}
    instance_counts = {}
    all_instances = {}

    for list_name in lists:
        show_args = ["rems", "show", list_name, "--format", "json"]
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

            item_dict = {
                "project": list_name,
                "title": title,
                "status": status,
                "source": "reminders",
                "due": item.get("dueDate", ""),
                "completionDate": item.get("completionDate", ""),
                "creationDate": item.get("creationDate", ""),
                "notes": item.get("notes", ""),
                "url": item.get("url", ""),
                "priority": item.get("priority", 0),
                "recurrence": item.get("recurrence", ""),
                "externalId": item.get("externalId", ""),
            }

            all_instances.setdefault(key, []).append(dict(item_dict))

            if key not in reminders:
                reminders[key] = item_dict
            else:
                existing = reminders[key]
                # Pending item wins over completed for status/due
                if status == "pending" and existing["status"] != "pending":
                    existing["status"] = status
                    existing["due"] = item.get("dueDate", "")
                    existing["externalId"] = item.get("externalId", "")
                elif not existing["due"] and item.get("dueDate", ""):
                    existing["due"] = item["dueDate"]
                if not existing["notes"] and item.get("notes", ""):
                    existing["notes"] = item["notes"]
    return reminders, instance_counts, all_instances


def find_tw_uuids(project, title, status_filter=None):
    """Find all TW task UUIDs matching project and description.

    Matches against both prefixed ('Project: title') and unprefixed ('title')
    descriptions for backward compatibility during migration.
    """
    result = subprocess.run(
        ["task", f"project.is:{project}", "export"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return []
    uuids = []
    legacy_prefixed = f"{project}: {title}"
    try:
        for t in json.loads(result.stdout):
            desc = t.get("description", "")
            if desc == title or desc == legacy_prefixed:
                task_status = t.get("status", "")
                # Normalize "waiting" to "pending" for filter comparison
                if task_status == "waiting":
                    task_status = "pending"
                if status_filter and task_status != status_filter:
                    continue
                uuids.append(t["uuid"])
    except json.JSONDecodeError:
        pass
    return uuids
