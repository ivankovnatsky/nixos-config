#!/usr/bin/env python3
"""Taskmanager: unified task management across Apple Reminders and Taskwarrior."""

import json
import os
import platform
import re
import shutil
import subprocess
import tempfile

import click


def has_command(cmd):
    return shutil.which(cmd) is not None


def is_darwin():
    return platform.system() == "Darwin"


_verbose = False


def run(cmd, stdin_text=None):
    if _verbose:
        click.echo(f"  >> {' '.join(cmd)}", err=True)
    result = subprocess.run(cmd, capture_output=True, text=True, input=stdin_text)
    if result.returncode != 0:
        click.echo(f"Error running {' '.join(cmd)}: {result.stderr.strip()}", err=True)
    return result


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
    for task in json.loads(result.stdout):
        project = task.get("project", "")
        desc = task.get("description", "")
        status = task.get("status", "pending")

        # Skip recurring parent templates
        if status == "recurring":
            continue

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
        result = subprocess.run(
            ["rems", "show-lists"], capture_output=True, text=True
        )
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
                "priority": item.get("priority", 0),
                "recurrence": item.get("recurrence", ""),
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
                elif not existing["due"] and item.get("dueDate", ""):
                    existing["due"] = item["dueDate"]
                if not existing["notes"] and item.get("notes", ""):
                    existing["notes"] = item["notes"]
    return reminders, instance_counts, all_instances


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


def date_key(date_str):
    """Normalize date+time for instance matching.

    Strips punctuation to a compact form (YYYYMMDDTHHMMSS) so TW format
    (20250808T210000Z) and Rem format (2025-08-08T21:00:00) compare equal.
    """
    if not date_str:
        return ""
    clean = normalize_date(date_str)
    # Strip trailing Z for comparison (both are UTC)
    return clean.rstrip("Z")


def match_instances(tw_list, rem_list):
    """Match multi-instance items by due date.

    Two passes: first match same-status items (completed↔completed,
    pending↔pending), then cross-status. This prevents a pending item
    from stealing a completed item's date match.

    Returns (matched_pairs, tw_unmatched, rem_unmatched) where:
    - matched_pairs: list of (tw_item, rem_item) tuples
    - tw_unmatched: list of tw items with no Reminders match
    - rem_unmatched: list of rem items with no TW match
    """
    matched = []
    rem_available = list(rem_list)

    def local_date(date_str):
        """Extract local YYYY-MM-DD for date-only comparison."""
        loc = format_date_local(date_str)
        return loc[:10] if loc else ""

    def try_match(tw_items, same_status_only):
        """Match TW items to Rem items by due date + completion date.

        Three-tier matching:
        1. Strong: due date + completion date both match
        2. Medium: due date matches (completion differs or missing)
        3. Weak: both have no due date, completion date matches
        """
        unmatched = []
        for tw_item in tw_items:
            tw_due = local_date(tw_item.get("due", ""))
            tw_end = local_date(tw_item.get("end", ""))

            strong = []
            medium = []
            weak = []
            fallback = []

            for i, rem_item in enumerate(rem_available):
                same = tw_item["status"] == rem_item["status"]
                if same_status_only and not same:
                    continue
                if not same_status_only and same:
                    continue

                rem_due = local_date(rem_item.get("due", ""))
                rem_comp = local_date(rem_item.get("completionDate", ""))

                if tw_due and rem_due and tw_due == rem_due:
                    if tw_end and rem_comp and tw_end == rem_comp:
                        strong.append((i, rem_item))
                    else:
                        medium.append((i, rem_item))
                elif not tw_due and not rem_due:
                    if tw_end and rem_comp and tw_end == rem_comp:
                        weak.append((i, rem_item))
                    elif same:
                        # Both have no due date, same status — prefer notes match
                        tw_ann = "; ".join(a.get("description", "") for a in tw_item.get("annotations", []))
                        rem_notes = (rem_item.get("notes") or "").strip()
                        if tw_ann and rem_notes and tw_ann == rem_notes:
                            weak.append((i, rem_item))
                        else:
                            fallback.append((i, rem_item))

            best = (strong or medium or weak or fallback or [None])[0]
            if best:
                matched.append((tw_item, best[1]))
                rem_available.pop(best[0])
            else:
                unmatched.append(tw_item)
        return unmatched

    # Pass 1: match same-status items by due date
    tw_remaining = try_match(tw_list, same_status_only=True)
    # Pass 2: match remaining cross-status items
    tw_unmatched = try_match(tw_remaining, same_status_only=False)

    # Pass 3: recurring completion reconciliation
    # When a recurring item is completed in Reminders, the completed instance
    # may lose its due date while TW still has the pending instance with the
    # original due. Match unmatched TW pending with unmatched Rem completed
    # (and vice versa) when one side has a due date and the other doesn't.
    if tw_unmatched and rem_available:
        tw_still_unmatched = []
        for tw_item in tw_unmatched:
            tw_due = local_date(tw_item.get("due", ""))
            best = None
            for i, rem_item in enumerate(rem_available):
                if tw_item["status"] == rem_item["status"]:
                    continue
                rem_due = local_date(rem_item.get("due", ""))
                # One side has due, the other doesn't — recurring completion
                if (tw_due and not rem_due) or (not tw_due and rem_due):
                    best = (i, rem_item)
                    break
            if best:
                matched.append((tw_item, best[1]))
                rem_available.pop(best[0])
            else:
                tw_still_unmatched.append(tw_item)
        tw_unmatched = tw_still_unmatched

    # Pass 4: pair remaining unmatched items from the same recurring group.
    # Handles: (a) same-status with mismatched due dates (recurring next-instance),
    # (b) cross-status with no due dates (item completed in one system but not the other).
    if tw_unmatched and rem_available:
        tw_still_unmatched = []
        for tw_item in tw_unmatched:
            tw_due = local_date(tw_item.get("due", ""))
            best = None
            for i, rem_item in enumerate(rem_available):
                rem_due = local_date(rem_item.get("due", ""))
                same_status = tw_item["status"] == rem_item["status"]
                # Same status, one side has due and the other doesn't
                if same_status and ((tw_due and not rem_due) or (not tw_due and rem_due)):
                    best = (i, rem_item)
                    break
                # Cross-status, both have no due (completed in one system)
                if not same_status and not tw_due and not rem_due:
                    best = (i, rem_item)
                    break
            if best:
                matched.append((tw_item, best[1]))
                rem_available.pop(best[0])
            else:
                tw_still_unmatched.append(tw_item)
        tw_unmatched = tw_still_unmatched

    return matched, tw_unmatched, rem_available


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
    if rem_notes and rem_notes not in tw_ann_texts:
        diffs.append(("notes", rem_notes_display, tw_notes_display))
    elif not rem_notes and tw_ann_texts:
        diffs.append(("notes", rem_notes_display, tw_notes_display))
    elif rem_notes and tw_ann_texts and any(a not in rem_notes for a in tw_ann_texts):
        diffs.append(("notes", rem_notes_display, tw_notes_display))

    # Completion date — only report when Rem has older (more original) date,
    # or when status is changing to completed (Rem completed, TW not yet)
    tw_end = format_date_local(tw.get("end", ""))
    rem_completion = format_date_local(rem.get("completionDate", ""))
    if tw_end != rem_completion and (tw_end or rem_completion):
        if rem["status"] == "completed" and tw["status"] != "completed":
            # Status changing — always show completion date
            diffs.append(("completed", rem_completion or "''", tw_end or "''"))
        elif rem_completion and tw_end and rem_completion < tw_end:
            # Both completed — only sync when Rem has older date
            diffs.append(("completed", rem_completion or "''", tw_end or "''"))

    # Creation date — only report when Rem has older (more original) date
    tw_entry = format_date_local(tw.get("entry", ""))
    rem_creation = format_date_local(rem.get("creationDate", ""))
    if rem_creation and tw_entry and rem_creation < tw_entry:
        diffs.append(("created", rem_creation or "''", tw_entry or "''"))

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
    tw_tasks, tw_counts, tw_instances = get_tw_tasks(project_filter)

    reminder_tasks, rem_counts, rem_instances = get_reminders(project_filter)

    # Detect recurrence from Reminders instances
    recurrence_info = {}
    for key, instances in rem_instances.items():
        for inst in instances:
            rec = inst.get("recurrence", "")
            if rec:
                recurrence_info[key] = rec
                break

    multi_instance = {
        k for k, c in tw_counts.items() if c > 1
    } | {k for k, c in rem_counts.items() if c > 1}

    # Handle multi-instance items via instance-level matching by due date
    instance_matched = set()
    instance_rem_only = {}
    instance_tw_only = {}
    instance_metadata_diffs = {}

    if multi_instance:
        if _verbose:
            click.echo(
                f"\nMatching {len(multi_instance)} recurring/multi-instance"
                " item(s) by due date...",
                err=True,
            )
        for key in sorted(multi_instance):
            if _verbose:
                rec = recurrence_info.get(key, "")
                rec_label = f" (recurring: {rec})" if rec else ""
                click.echo(f"  {key[0]}: {key[1]}{rec_label}", err=True)

            tw_list = tw_instances.get(key, [])
            rem_list = rem_instances.get(key, [])

            matched_pairs, tw_unmatched, rem_unmatched = match_instances(
                tw_list, rem_list
            )

            for tw_item, rem_item in matched_pairs:
                due = date_key(tw_item.get("due", "")) or date_key(
                    rem_item.get("due", "")
                )
                due_display = format_date_local(
                    tw_item.get("due", "") or rem_item.get("due", "")
                ) or due
                instance_key = (key[0], f"{key[1]} [{due_display}]")
                instance_matched.add(instance_key)

                diffs = compare_metadata(tw_item, rem_item)
                if diffs:
                    instance_metadata_diffs[instance_key] = {
                        "diffs": diffs,
                        "tw": tw_item,
                        "rem": rem_item,
                    }

            for tw_item in tw_unmatched:
                due = date_key(tw_item.get("due", ""))
                due_display = format_date_local(tw_item.get("due", "")) or due
                instance_key = (key[0], f"{key[1]} [{due_display}]")
                # Disambiguate when multiple unmatched items share the same due
                while instance_key in instance_tw_only:
                    instance_key = (instance_key[0], instance_key[1] + " #dup")
                instance_tw_only[instance_key] = tw_item

            for rem_item in rem_unmatched:
                due = date_key(rem_item.get("due", ""))
                due_display = format_date_local(rem_item.get("due", "")) or due
                instance_key = (key[0], f"{key[1]} [{due_display}]")
                while instance_key in instance_rem_only:
                    instance_key = (instance_key[0], instance_key[1] + " #dup")
                instance_rem_only[instance_key] = rem_item

    # Single-instance items: existing logic
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

    # Merge instance-level results into main results
    matched.update(instance_matched)
    rem_only.update(instance_rem_only)
    tw_only.update(instance_tw_only)
    metadata_diffs.update(instance_metadata_diffs)

    # Track which keys came from multi-instance matching (for --recurring filter)
    multi_keys = set()
    for k in instance_matched:
        multi_keys.add(k)
    for k in instance_rem_only:
        multi_keys.add(k)
    for k in instance_tw_only:
        multi_keys.add(k)
    for k in instance_metadata_diffs:
        multi_keys.add(k)

    return rem_only, tw_only, matched, metadata_diffs, multi_keys


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
    if field == "due":
        rem_e = rem_val in empty
        tw_e = tw_val in empty
        if rem_e and not tw_e:
            return "tw_to_rem"
        if tw_e and not rem_e:
            return "rem_to_tw"
        # Same calendar date but one is midnight (date-only) — sync the
        # specific time to the midnight side instead of overwriting it.
        if (
            len(rem_val) >= 10
            and len(tw_val) >= 10
            and rem_val[:10] == tw_val[:10]
        ):
            rem_midnight = rem_val.endswith("T00:00:00")
            tw_midnight = tw_val.endswith("T00:00:00")
            if rem_midnight and not tw_midnight:
                return "tw_to_rem"
            if tw_midnight and not rem_midnight:
                return "rem_to_tw"
        # Both have values — prefer older (more original) date
        if rem_val < tw_val:
            return "rem_to_tw"
        return "tw_to_rem"
    rem_empty = rem_val in empty
    tw_empty = tw_val in empty
    if rem_empty and not tw_empty:
        return "tw_to_rem"
    if tw_empty and not rem_empty:
        return "rem_to_tw"
    # Both have values — prefer the longer/more complete one
    if field == "notes" and len(str(tw_val)) > len(str(rem_val)):
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


def find_tw_uuids(project, prefixed_title, status_filter=None):
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
                if status_filter and t.get("status", "") != status_filter:
                    continue
                uuids.append(t["uuid"])
    except json.JSONDecodeError:
        pass
    return uuids


def find_reminder_index(list_name, prefixed_title, completed_only=False, include_completed=True, due_date=None, notes_empty=None):
    """Find reminder index by list and prefixed title.

    Optional filters:
    - completed_only: only search completed items
    - include_completed: include completed items in the view (default True)
    - due_date: match by due date (date_key comparison)
    - notes_empty: True=only match items with empty notes, False=only with notes
    """
    cmd = ["rems", "show", list_name, "--format", "json"]
    if completed_only:
        cmd.append("--only-completed")
    elif include_completed:
        cmd.append("--include-completed")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return None
    try:
        # First try exact match with all filters
        items = json.loads(result.stdout)
        candidates = []
        for i, item in enumerate(items):
            if item.get("title", "") != prefixed_title:
                continue
            if due_date:
                item_due = format_date_local(item.get("dueDate", ""))
                target_due = format_date_local(due_date)
                if item_due[:10] != target_due[:10]:
                    continue
            if notes_empty is True and (item.get("notes") or "").strip():
                continue
            if notes_empty is False and not (item.get("notes") or "").strip():
                continue
            candidates.append(i)
        if candidates:
            return candidates[0]
        # Fall back to title-only match
        for i, item in enumerate(items):
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
    return "\n    ".join(parts)


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
                        # Also sync completion date when marking done
                        raw_end = rem.get("completionDate", "")
                        if raw_end:
                            tw_updates["end"] = raw_end
                    else:
                        tw_updates["status"] = "pending"
                elif flow == "tw_to_rem":
                    if tw["status"] == "completed":
                        rem_updates["status"] = "completed"
                    else:
                        rem_updates["status"] = "pending"

        if tw_updates:
            # Use stored UUID for instance-level items, fall back to title search
            tw_uuid = tw.get("uuid", "")
            if tw_uuid:
                uuids = [tw_uuid]
            else:
                tw_prefixed = f"{project}: {tw['title']}"
                uuids = find_tw_uuids(project, tw_prefixed)
            for uuid in uuids:
                modify_args = []
                if "title" in tw_updates:
                    modify_args.append(f"description:{tw_updates['title']}")
                if "due" in tw_updates:
                    modify_args.append(f"due:{tw_updates['due']}")
                if "entry" in tw_updates:
                    modify_args.append(f"entry:{tw_updates['entry']}")
                if "priority" in tw_updates:
                    modify_args.append(f"priority:{tw_updates['priority']}")
                # Set end before status change only if not completing
                if "end" in tw_updates and "status" not in tw_updates:
                    modify_args.append(f"end:{tw_updates['end']}")
                if modify_args:
                    result = run(["task", uuid, "modify"] + modify_args)
                    # If modify fails on a recurring task (e.g. can't remove due),
                    # delete the recurring parent to stop recurrence, then retry
                    if result.returncode != 0 and tw.get("recur", ""):
                        click.echo(f"    Recurring task detected — purging to remove recurrence")
                        # Delete first if not already deleted, then purge
                        del_result = run(["task", "rc.confirmation:off", uuid, "delete"])
                        if del_result.returncode != 0:
                            # Already deleted — just purge
                            pass
                        run(["task", "rc.confirmation:off", uuid, "purge"])
                if "notes" in tw_updates:
                    # Check if annotation already exists to avoid duplicates
                    existing_anns = tw.get("annotations", [])
                    existing_texts = {
                        a.get("description", "").strip() for a in existing_anns
                    }
                    if tw_updates["notes"].strip() not in existing_texts:
                        run(["task", uuid, "annotate", tw_updates["notes"]])
                if "status" in tw_updates:
                    if tw_updates["status"] == "completed":
                        run(["task", "rc.confirmation:off", uuid, "done"])
                        # Set end after done — task done overwrites end with now
                        if "end" in tw_updates:
                            run(["task", uuid, "modify", f"end:{tw_updates['end']}"])
                    else:
                        run(["task", uuid, "modify", "status:pending"])
            if uuids:
                count += 1
                click.echo(
                    f"  ~ Taskwarrior: {prefixed}\n    {format_update_summary(tw_updates)}"
                )

        if rem_updates and is_darwin() and has_command("rems"):
            rem_prefixed = f"{project}: {rem['title']}"
            edit_args = [
                "rems",
                "edit",
                project,
                rem_prefixed,
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
                    complete_cmd = ["rems", "complete", project, rem_prefixed]
                    raw_end = tw.get("end", "")
                    if raw_end:
                        complete_cmd.extend(["--completion-date", tw_date_to_iso(raw_end)])
                    run(complete_cmd)
                else:
                    run(["rems", "uncomplete", project, rem_prefixed])
            count += 1
            click.echo(
                f"  ~ Reminders: {prefixed}\n    {format_update_summary(rem_updates)}"
            )

    return count


class TreeGroup(click.Group):
    def format_commands(self, ctx, formatter):
        commands = []
        for subname in self.list_commands(ctx):
            cmd = self.get_command(ctx, subname)
            if cmd is None or cmd.hidden:
                continue
            help_text = cmd.get_short_help_str(limit=formatter.width)
            commands.append((subname, cmd, help_text))

        if commands:
            with formatter.section("Commands"):
                for subname, cmd, help_text in commands:
                    formatter.write(f"  {subname:<12}{help_text}\n")
                    if isinstance(cmd, click.Group):
                        sub_ctx = click.Context(cmd, info_name=subname, parent=ctx)
                        for child_name in cmd.list_commands(sub_ctx):
                            child = cmd.get_command(sub_ctx, child_name)
                            if child and not child.hidden:
                                child_help = child.get_short_help_str(limit=formatter.width)
                                formatter.write(f"    {child_name:<8}{child_help}\n")


@click.group(cls=TreeGroup)
def cli():
    """Unified task management across Apple Reminders and Taskwarrior."""


@cli.group(name="all")
def all_cmds():
    """Commands that work with both Reminders and Taskwarrior."""


REMINDERS_ALIASES = ("r", "rem", "rems")


@cli.group(name="reminders")
def reminders_group():
    """Reminders-only commands."""


# Register aliases — same group object, hidden from help
for _alias in REMINDERS_ALIASES:
    cli.add_command(reminders_group, _alias)
reminders_group.hidden_aliases = set(REMINDERS_ALIASES)

TW_ALIASES = ("t", "tw")


@cli.group(name="taskwarrior")
def tw_group():
    """Taskwarrior-only commands."""


for _alias in TW_ALIASES:
    cli.add_command(tw_group, _alias)
tw_group.hidden_aliases = set(TW_ALIASES)


# Patch TreeGroup to skip hidden aliases
_orig_format = TreeGroup.format_commands


def _format_no_aliases(self, ctx, formatter):
    # Temporarily hide alias entries
    hidden = set()
    for name, cmd in list(self.commands.items()):
        if hasattr(cmd, "hidden_aliases") and name in cmd.hidden_aliases:
            hidden.add(name)
    orig_list = self.list_commands
    self.list_commands = lambda ctx: [n for n in orig_list(ctx) if n not in hidden]
    _orig_format(self, ctx, formatter)
    self.list_commands = orig_list


TreeGroup.format_commands = _format_no_aliases


@reminders_group.command(name="sort")
@click.option("--source", default=None, help="Limit to a single source list.")
@click.option("--approve", is_flag=True, default=False, help="Skip all confirmation prompts.")
@click.option("--interactive", is_flag=True, default=False, help="Confirm each item individually.")
@click.option("--create/--no-create", default=True, help="Auto-create missing lists (default: enabled).")
@click.option("--verbose", is_flag=True, default=False, help="Show commands being run.")
def sort_reminders(source, approve, interactive, create, verbose):
    """Sort prefixed reminders into their matching lists.

    Scans all lists for items whose '<Prefix>: ' doesn't match the current
    list and moves them to the correct one. Use --source to limit to one list.
    """
    global _verbose
    _verbose = verbose

    if not (is_darwin() and has_command("rems")):
        click.echo("Error: reminders CLI not available", err=True)
        raise SystemExit(1)

    # Get all existing list names
    result = subprocess.run(
        ["rems", "show-lists"], capture_output=True, text=True
    )
    if result.returncode != 0:
        click.echo("Error: could not fetch reminder lists", err=True)
        raise SystemExit(1)
    existing_lists = set(result.stdout.strip().splitlines())

    lists_to_scan = [source] if source else sorted(existing_lists)

    # Collect moves across all scanned lists
    moves = []
    for list_name in lists_to_scan:
        result = subprocess.run(
            ["rems", "show", list_name, "--format", "json"],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            continue

        try:
            items = json.loads(result.stdout)
        except json.JSONDecodeError:
            continue

        for i, item in enumerate(items):
            title = item.get("title", "")
            if item.get("isCompleted", False):
                continue
            if ": " not in title:
                continue
            prefix, rest = title.split(": ", 1)
            if not rest.strip():
                continue
            target_list = prefix
            # Skip if already in the correct list
            if target_list == list_name:
                continue
            needs_create = target_list not in existing_lists
            if needs_create and not create:
                click.echo(f"  skip (no list): {title}")
                continue
            moves.append({
                "source": list_name,
                "index": i,
                "title": title,
                "target": target_list,
                "needs_create": needs_create,
                "external_id": item.get("externalId", ""),
            })

    if not moves:
        return

    # Display plan
    lists_to_create = sorted({m["target"] for m in moves if m["needs_create"]})
    if lists_to_create:
        click.echo(f"Lists to create: {', '.join(lists_to_create)}")

    click.echo()
    click.echo(f"{len(moves)} item(s) to move:")
    click.echo()
    for m in moves:
        create_tag = " (new list)" if m["needs_create"] else ""
        click.echo(f"  {m['source']}: {m['title']}")
        click.echo(f"    → {m['target']}{create_tag}")

    if not approve:
        click.echo()
        if not click.confirm("Proceed?"):
            click.echo("Aborted.")
            return

    # Execute moves in reverse index order to avoid index shifting
    created_lists = set()
    moved = 0
    for m in reversed(moves):
        target = m["target"]
        create_tag = " (new list)" if m["needs_create"] and target not in created_lists else ""

        if interactive:
            click.echo()
            click.echo(f"  {m['title']}")
            click.echo(f"    → {target}{create_tag}")
            if not click.confirm("  Move?"):
                continue

        # Create list if needed
        if m["needs_create"] and target not in created_lists:
            res = run(["rems", "new-list", target])
            if res.returncode != 0:
                click.echo(f"  ERROR creating list '{target}', skipping", err=True)
                continue
            created_lists.add(target)
            click.echo(f"  Created list: {target}")

        # Move the item (use externalId if available, else index)
        lookup = m["external_id"] if m["external_id"] else str(m["index"])
        res = run(["rems", "move", m["source"], lookup, target])
        if res.returncode != 0:
            click.echo(f"  ERROR moving: {m['title']}", err=True)
            continue

        moved += 1
        click.echo(f"  Moved: {m['source']}: {m['title']} → {target}")

    click.echo()
    click.echo(f"Done. Moved {moved}/{len(moves)} item(s).")


@tw_group.command(name="sort")
@click.option("--project", default=None, help="Limit to a single project.")
@click.option("--approve", is_flag=True, default=False, help="Skip all confirmation prompts.")
@click.option("--interactive", is_flag=True, default=False, help="Confirm each item individually.")
@click.option("--verbose", is_flag=True, default=False, help="Show commands being run.")
def sort_tw(project, approve, interactive, verbose):
    """Sort prefixed TW tasks into their matching projects.

    Scans all tasks (or a single --project) for items whose '<Prefix>: '
    doesn't match the current project and moves them to the correct one.
    """
    global _verbose
    _verbose = verbose

    if not has_command("task"):
        click.echo("Error: task (Taskwarrior) CLI not available", err=True)
        raise SystemExit(1)

    cmd = ["task"]
    if project:
        cmd.append(f"project.is:{project}")
    cmd.extend(["status:pending", "export"])

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        click.echo("Error: could not export Taskwarrior tasks", err=True)
        raise SystemExit(1)

    try:
        tasks = json.loads(result.stdout)
    except json.JSONDecodeError:
        click.echo("Error: could not parse Taskwarrior export", err=True)
        raise SystemExit(1)

    moves = []
    for task in tasks:
        if task.get("status") == "recurring":
            continue
        desc = task.get("description", "")
        current_project = task.get("project", "")
        uuid = task.get("uuid", "")
        if ": " not in desc:
            continue
        prefix, rest = desc.split(": ", 1)
        if not rest.strip():
            continue
        target_project = prefix
        if target_project == current_project:
            continue
        moves.append({
            "uuid": uuid,
            "description": desc,
            "current_project": current_project,
            "target_project": target_project,
        })

    if not moves:
        return

    click.echo()
    click.echo(f"{len(moves)} task(s) to move:")
    click.echo()
    for m in moves:
        src = m['current_project'] or '(no project)'
        click.echo(f"  {src}: {m['description']}")
        click.echo(f"    → project:{m['target_project']}")

    if not approve:
        click.echo()
        if not click.confirm("Proceed?"):
            click.echo("Aborted.")
            return

    moved = 0
    for m in moves:
        if interactive:
            click.echo()
            click.echo(f"  {m['description']}")
            click.echo(f"    → project:{m['target_project']}")
            if not click.confirm("  Move?"):
                continue

        res = run(["task", m["uuid"], "modify", f"project:{m['target_project']}"])
        if res.returncode == 0:
            moved += 1
            click.echo(f"  Moved: {m['description']} → project:{m['target_project']}")
        else:
            click.echo(f"  ERROR moving: {m['description']}", err=True)

    click.echo()
    click.echo(f"Done. Moved {moved}/{len(moves)} task(s).")


@all_cmds.command(name="sort")
@click.option("--source", default=None, help="Limit Reminders to a single source list.")
@click.option("--project", default=None, help="Limit Taskwarrior to a single project.")
@click.option("--approve", is_flag=True, default=False, help="Skip all confirmation prompts.")
@click.option("--interactive", is_flag=True, default=False, help="Confirm each item individually.")
@click.option("--create/--no-create", default=True, help="Auto-create missing Reminders lists (default: enabled).")
@click.option("--verbose", is_flag=True, default=False, help="Show commands being run.")
@click.pass_context
def sort_all(ctx, source, project, approve, interactive, create, verbose):
    """Sort prefixed items in both Reminders and Taskwarrior."""
    global _verbose
    _verbose = verbose

    if is_darwin() and has_command("rems"):
        ctx.invoke(
            sort_reminders,
            source=source,
            approve=approve,
            interactive=interactive,
            create=create,
            verbose=verbose,
        )

    if has_command("task"):
        ctx.invoke(
            sort_tw,
            project=project,
            approve=approve,
            interactive=interactive,
            verbose=verbose,
        )



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


def filter_by_recurring(rem_only, tw_only, metadata_diffs, multi_keys, recurring):
    """Filter results to only recurring or only non-recurring items."""
    if recurring is None:
        return rem_only, tw_only, metadata_diffs
    if recurring:
        rem_only = {k: v for k, v in rem_only.items() if k in multi_keys}
        tw_only = {k: v for k, v in tw_only.items() if k in multi_keys}
        metadata_diffs = {k: v for k, v in metadata_diffs.items() if k in multi_keys}
    else:
        rem_only = {k: v for k, v in rem_only.items() if k not in multi_keys}
        tw_only = {k: v for k, v in tw_only.items() if k not in multi_keys}
        metadata_diffs = {
            k: v for k, v in metadata_diffs.items() if k not in multi_keys
        }
    return rem_only, tw_only, metadata_diffs


@all_cmds.command()
@click.option("--project", default=None, help="Scope to a single project/list.")
@click.option(
    "--projects", default=None, help="Comma-separated project/list names."
)
@click.option("--filter", default=None, help="Filter to items matching title substring.")
@click.option(
    "--notes", is_flag=True, default=False, help="Show only notes/annotations drift."
)
@click.option(
    "--recurring/--no-recurring",
    default=None,
    help="Show only recurring (--recurring) or non-recurring (--no-recurring) items.",
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
@click.option("--verbose", is_flag=True, default=False, help="Show commands being run.")
@click.option("--sort-first/--no-sort-first", default=True, help="Run sort before computing drift (default: enabled).")
@click.pass_context
def drift(ctx, project, projects, filter, notes, recurring, source, destination, verbose, sort_first):
    """Show drift between Reminders and Taskwarrior."""
    global _verbose
    _verbose = verbose

    if sort_first:
        ctx.invoke(
            sort_all,
            source=None,
            project=project,
            approve=False,
            interactive=False,
            create=True,
            verbose=verbose,
        )

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
    all_multi_keys = set()
    for proj in project_list:
        rem_only, tw_only, matched, metadata_diffs, multi_keys = compute_drift(proj)
        all_rem_only.update(rem_only)
        all_tw_only.update(tw_only)
        all_matched.update(matched)
        all_metadata_diffs.update(metadata_diffs)
        all_multi_keys.update(multi_keys)

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

    all_rem_only, all_tw_only, all_metadata_diffs = filter_by_recurring(
        all_rem_only, all_tw_only, all_metadata_diffs, all_multi_keys, recurring
    )

    print_drift(
        all_rem_only, all_tw_only, all_matched, all_metadata_diffs, direction=source
    )


@all_cmds.command()
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
    "--recurring/--no-recurring",
    default=None,
    help="Sync only recurring (--recurring) or non-recurring (--no-recurring) items.",
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
@click.option("--verbose", is_flag=True, default=False, help="Show commands being run.")
@click.option(
    "--purge-duplicates",
    is_flag=True,
    default=False,
    help="Delete TW-only duplicate tasks that have no Reminders counterpart. Always interactive.",
)
@click.option(
    "--complete-orphans",
    is_flag=True,
    default=False,
    help="Complete TW-only pending tasks whose title has completed history. Always interactive.",
)
@click.option(
    "--purge-recurring",
    is_flag=True,
    default=False,
    help="Delete and purge TW recurring parent tasks. Always interactive.",
)
@click.option("--sort-first/--no-sort-first", default=True, help="Run sort before syncing (default: enabled).")
@click.pass_context
def sync(ctx, project, projects, filter, approve, interactive, notes, recurring, source, destination, verbose, purge_duplicates, complete_orphans, purge_recurring, sort_first):
    """Sync missing items to both systems."""
    global _verbose
    _verbose = verbose

    if sort_first:
        ctx.invoke(
            sort_all,
            source=None,
            project=project,
            approve=False,
            interactive=False,
            create=True,
            verbose=verbose,
        )

    if not project and not projects and not interactive and not approve:
        interactive = True
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
    all_multi_keys = set()
    for proj in project_list:
        rem_only, tw_only, matched, metadata_diffs, multi_keys = compute_drift(proj)
        all_rem_only.update(rem_only)
        all_tw_only.update(tw_only)
        all_matched.update(matched)
        all_metadata_diffs.update(metadata_diffs)
        all_multi_keys.update(multi_keys)

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

    rem_only, tw_only, metadata_diffs = filter_by_recurring(
        rem_only, tw_only, metadata_diffs, all_multi_keys, recurring
    )

    if not interactive:
        print_drift(rem_only, tw_only, matched, metadata_diffs, direction=source)

    total = len(rem_only) + len(tw_only) + len(metadata_diffs)
    if total == 0 and not purge_duplicates and not complete_orphans and not purge_recurring:
        return

    if not interactive:
        parts = []
        if rem_only:
            parts.append(f"{len(rem_only)} items to Taskwarrior")
        if tw_only:
            parts.append(f"{len(tw_only)} items to Reminders")
        if metadata_diffs:
            parts.append(f"{len(metadata_diffs)} metadata updates")
        click.echo()
        click.echo(f"Will sync: {', '.join(parts)}.")
        if not approve and not click.confirm("Proceed?"):
            click.echo("Aborted.")
            return

    # Reminders-only → add to Taskwarrior
    for item in rem_only.values():
        proj = item["project"]
        prefixed = f"{proj}: {item['title']}"
        if interactive:
            click.echo()
            click.echo("Reminders only:")
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
        # Check if a pending TW task with the same title already exists (avoid duplicates)
        existing_uuids = find_tw_uuids(proj, prefixed, status_filter="pending")
        if existing_uuids and item["status"] == "completed":
            # Complete the existing task instead of creating a duplicate
            uuid = existing_uuids[0]
            run(["task", "rc.confirmation:off", uuid, "done"])
            click.echo(f"  ~ Taskwarrior: {prefixed} (completed existing)")
            raw_end = item.get("completionDate", "")
            if raw_end:
                run(["task", uuid, "modify", f"end:{raw_end}"])
        elif existing_uuids:
            # Existing pending task — update metadata instead of creating duplicate
            uuid = existing_uuids[0]
            mods = []
            raw_due = item.get("due", "")
            if raw_due:
                mods.append(f"due:{raw_due}")
            tw_prio = REMINDERS_PRIORITY_MAP.get(item.get("priority", 0), "")
            if tw_prio:
                mods.append(f"priority:{tw_prio}")
            if mods:
                run(["task", uuid, "modify"] + mods)
            item_notes = (item.get("notes") or "").strip()
            if item_notes:
                run(["task", uuid, "annotate", item_notes])
            click.echo(f"  ~ Taskwarrior: {prefixed} (updated existing)")
        else:
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

                # Find the UUID of the newly created task from task add output
                task_id_match = re.search(r"Created task (\d+)\.", result.stdout)
                uuid = ""
                if task_id_match:
                    tid = task_id_match.group(1)
                    find = subprocess.run(
                        ["task", tid, "export"],
                        capture_output=True,
                        text=True,
                    )
                    if find.returncode == 0:
                        try:
                            exported = json.loads(find.stdout)
                            if exported:
                                uuid = exported[0].get("uuid", "")
                        except json.JSONDecodeError:
                            pass
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
                        run(["task", "rc.confirmation:off", uuid, "done"])
                    raw_end = item.get("completionDate", "")
                    if raw_end:
                        run(["task", uuid, "modify", f"end:{raw_end}"])

    # Taskwarrior-only → add to Reminders
    if is_darwin() and has_command("rems"):
        existing = subprocess.run(
            ["rems", "show-lists"], capture_output=True, text=True
        )
        existing_lists = set(existing.stdout.strip().splitlines())

        for item in tw_only.values():
            proj = item["project"]
            prefixed = f"{proj}: {item['title']}"

            # Never copy deleted TW tasks to Reminders
            if item.get("status") == "deleted":
                continue
            # Skip TW→Rem copy when --complete-orphans or --purge-duplicates will handle them
            if complete_orphans and item.get("status") == "pending":
                continue
            if purge_duplicates:
                continue
            if purge_recurring:
                continue

            if interactive:
                click.echo()
                click.echo("Taskwarrior only:")
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
                run(["rems", "new-list", proj])
                existing_lists.add(proj)

            add_cmd = ["rems", "add", proj, prefixed]

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
                    complete_cmd = ["rems", "complete", proj, prefixed]
                    raw_end = item.get("end", "")
                    if raw_end:
                        complete_cmd.extend(["--completion-date", tw_date_to_iso(raw_end)])
                    run(complete_cmd)

    # Sync metadata for matched items with drift
    if metadata_diffs:
        meta_count = sync_metadata(metadata_diffs, direction=source, interactive=interactive)
        if meta_count:
            click.echo()
            click.echo(f"Updated metadata on {meta_count} items.")

    # Purge TW duplicates (always interactive, requires explicit confirmation)
    # Detects both TW-only items and TW-internal duplicates (multiple pending
    # tasks with the same project+description).
    if purge_duplicates:
        purge_count = 0

        # 1. TW-only items with no Reminders counterpart
        if tw_only:
            click.echo()
            click.echo(f"--- TW-only items ({len(tw_only)}) ---")
            for key, item in tw_only.items():
                proj = item["project"]
                prefixed = f"{proj}: {item['title']}"
                uuid = item.get("uuid", "")
                due = format_date_local(item.get("due", ""))
                status = item.get("status", "pending")
                click.echo()
                click.echo(f"  TW-only: {prefixed}")
                click.echo(f"    status: {status}")
                if due:
                    click.echo(f"    due: {due}")
                if uuid:
                    click.echo(f"    uuid: {uuid[:8]}")
                if not click.confirm("  DELETE from Taskwarrior?", default=False):
                    continue
                if uuid:
                    if status != "deleted":
                        result = run(["task", "rc.confirmation:off", uuid, "delete"])
                        if result.returncode != 0:
                            click.echo(f"  ! Failed to delete: {prefixed}")
                            continue
                    result = run(["task", "rc.confirmation:off", uuid, "purge"])
                    if result.returncode == 0:
                        click.echo(f"  - Taskwarrior: {prefixed} (purged)")
                        purge_count += 1
                    else:
                        click.echo(f"  ! Failed to purge: {prefixed}")

        # 2. TW-internal duplicates: multiple pending tasks with same description
        click.echo()
        click.echo("--- Scanning for TW-internal duplicates ---")
        from collections import defaultdict
        tw_cmd = ["task"]
        for proj in (parse_projects(projects) if projects else [project] if project else []):
            if proj:
                tw_cmd.append(f"project.is:{proj}")
        tw_cmd.append("export")
        tw_result = subprocess.run(tw_cmd, capture_output=True, text=True)
        if tw_result.returncode == 0:
            try:
                all_tw = json.loads(tw_result.stdout)
            except json.JSONDecodeError:
                all_tw = []
            pending_by_desc = defaultdict(list)
            for t in all_tw:
                if t.get("status") == "pending":
                    key = (t.get("project", ""), t.get("description", ""))
                    pending_by_desc[key].append(t)

            def tw_meta_fingerprint(t):
                """Metadata fingerprint for duplicate detection."""
                return (
                    t.get("description", ""),
                    t.get("project", ""),
                    date_key(t.get("due", "")),
                    t.get("priority", ""),
                    len(t.get("annotations", [])),
                )

            dup_count = 0
            for key, tasks_list in sorted(pending_by_desc.items()):
                if len(tasks_list) <= 1:
                    continue
                # Group by metadata fingerprint — only items with identical
                # metadata are considered duplicates
                by_fp = defaultdict(list)
                for t in tasks_list:
                    by_fp[tw_meta_fingerprint(t)].append(t)
                for fp, group in by_fp.items():
                    if len(group) <= 1:
                        continue
                    # Keep the oldest (by entry date), offer to delete the rest
                    group.sort(key=lambda t: t.get("entry", ""))
                    keep = group[0]
                    dupes = group[1:]
                    click.echo()
                    click.echo(f"  {key[1]} ({len(group)} identical pending copies)")
                    click.echo(f"    keeping: uuid:{keep['uuid'][:8]} entry:{keep.get('entry','')[:10]}")
                    for d in dupes:
                        entry = d.get("entry", "")[:10]
                        click.echo(f"    duplicate: uuid:{d['uuid'][:8]} entry:{entry}")
                        if not click.confirm("    DELETE this duplicate?", default=False):
                            continue
                        result = run(["task", "rc.confirmation:off", d["uuid"], "delete"])
                        if result.returncode == 0:
                            click.echo(f"    - Deleted {d['uuid'][:8]}")
                            purge_count += 1
                            dup_count += 1
                        else:
                            click.echo(f"    ! Failed to delete {d['uuid'][:8]}")
            if dup_count == 0:
                click.echo("  No internal duplicates found.")

        if purge_count:
            click.echo()
            click.echo(f"Deleted {purge_count} TW duplicate(s).")

    # Complete TW-only pending orphans that have completed history
    if complete_orphans and tw_only:
        click.echo()
        click.echo(f"--- TW-only pending orphans ({len(tw_only)} items) ---")
        complete_count = 0
        for key, item in tw_only.items():
            if item.get("status") != "pending":
                continue
            proj = item["project"]
            prefixed = f"{proj}: {item['title']}"
            uuid = item.get("uuid", "")
            if not uuid:
                continue
            # Check if this title has completed history in TW
            all_uuids_result = subprocess.run(
                ["task", f"project.is:{proj}", "export"],
                capture_output=True, text=True,
            )
            has_completed = False
            if all_uuids_result.returncode == 0:
                try:
                    for t in json.loads(all_uuids_result.stdout):
                        if (t.get("description", "") == prefixed
                                and t.get("status") == "completed"):
                            has_completed = True
                            break
                except json.JSONDecodeError:
                    pass
            if not has_completed:
                continue
            click.echo()
            click.echo(f"  TW orphan: {prefixed}")
            click.echo(f"    uuid: {uuid[:8]}")
            click.echo(f"    has completed history in TW")
            if not click.confirm("  COMPLETE this task?", default=False):
                continue
            result = run(["task", "rc.confirmation:off", uuid, "done"])
            if result.returncode == 0:
                click.echo(f"  ~ Completed: {prefixed}")
                complete_count += 1
            else:
                click.echo(f"  ! Failed to complete: {prefixed}")
        if complete_count:
            click.echo()
            click.echo(f"Completed {complete_count} orphan(s).")

    # Purge TW recurring parent tasks
    if purge_recurring:
        click.echo()
        click.echo("--- Scanning for TW recurring parents ---")
        tw_cmd = ["task", "export"]
        tw_result = subprocess.run(tw_cmd, capture_output=True, text=True)
        purge_count = 0
        if tw_result.returncode == 0:
            try:
                all_tw = json.loads(tw_result.stdout)
            except json.JSONDecodeError:
                all_tw = []
            recurring_parents = [t for t in all_tw if t.get("status") == "recurring"]
            # Filter by project if specified
            if project or projects:
                proj_list = parse_projects(projects) if projects else [project]
                proj_set = {p for p in proj_list if p}
                if proj_set:
                    recurring_parents = [t for t in recurring_parents if t.get("project", "") in proj_set]
            if not recurring_parents:
                click.echo("  No recurring parents found.")
            for t in recurring_parents:
                desc = t.get("description", "")
                proj = t.get("project", "")
                recur = t.get("recur", "")
                uuid = t.get("uuid", "")
                due = format_date_local(t.get("due", ""))
                click.echo()
                click.echo(f"  Recurring parent: {desc}")
                click.echo(f"    project: {proj}")
                click.echo(f"    recur: {recur}")
                if due:
                    click.echo(f"    due: {due}")
                click.echo(f"    uuid: {uuid[:8]}")
                if not click.confirm("  DELETE and PURGE this recurring parent?", default=False):
                    continue
                # Find and delete child instances first
                children = [c for c in all_tw
                            if c.get("parent") == uuid and c.get("status") != "deleted"]
                for child in children:
                    run(["task", "rc.confirmation:off", child["uuid"], "delete"])
                # Delete the parent
                run(["task", "rc.confirmation:off", uuid, "delete"])
                # Purge children first, then parent
                for child in children:
                    run(["task", "rc.confirmation:off", child["uuid"], "purge"])
                result = run(["task", "rc.confirmation:off", uuid, "purge"])
                if result.returncode == 0:
                    click.echo(f"  - Purged: {desc} (+ {len(children)} child instance(s))")
                    purge_count += 1
                else:
                    click.echo(f"  ! Failed to purge: {desc}")
        if purge_count:
            click.echo()
            click.echo(f"Purged {purge_count} recurring parent(s).")

    click.echo()
    click.echo("Done.")


@all_cmds.command()
@click.option("--project", default=None, help="Scope to a single project/list.")
@click.option(
    "--projects", default=None, help="Comma-separated project/list names."
)
@click.option("--verbose", is_flag=True, default=False, help="Show commands being run.")
def verify(project, projects, verbose):
    """Verify item counts and statuses match between Reminders and Taskwarrior."""
    global _verbose
    _verbose = verbose

    project_list = parse_projects(projects) if projects else [project]
    from collections import Counter

    total_tw = 0
    total_rem = 0
    total_mismatch = 0
    status_issues = []

    for proj in project_list:
        tw_tasks, tw_counts, tw_instances = get_tw_tasks(proj)
        rem_tasks, rem_counts, rem_instances = get_reminders(proj)

        # Flatten all instances (excluding recurring parents, already filtered)
        tw_all = []
        for instances in tw_instances.values():
            tw_all.extend(instances)
        rem_all = []
        for instances in rem_instances.values():
            rem_all.extend(instances)

        # Count by prefixed title
        tw_titles = Counter(f"{t['project']}: {t['title']}" for t in tw_all)
        rem_titles = Counter(f"{r['project']}: {r['title']}" for r in rem_all)

        all_titles = sorted(set(tw_titles.keys()) | set(rem_titles.keys()))

        # Group by title for status check
        tw_by_title = {}
        for t in tw_all:
            key = f"{t['project']}: {t['title']}"
            tw_by_title.setdefault(key, []).append(t)
        rem_by_title = {}
        for r in rem_all:
            key = f"{r['project']}: {r['title']}"
            rem_by_title.setdefault(key, []).append(r)

        mismatches = []
        for title in all_titles:
            tc = tw_titles.get(title, 0)
            rc = rem_titles.get(title, 0)
            if tc != rc:
                mismatches.append((title, tc, rc))

            # Status breakdown
            tw_items = tw_by_title.get(title, [])
            rem_items = rem_by_title.get(title, [])
            tw_pending = sum(1 for t in tw_items if t["status"] == "pending")
            tw_completed = sum(1 for t in tw_items if t["status"] == "completed")
            tw_deleted = sum(1 for t in tw_items if t["status"] == "deleted")
            rem_pending = sum(1 for r in rem_items if r["status"] == "pending")
            rem_completed = sum(1 for r in rem_items if r["status"] == "completed")

            if tw_pending != rem_pending or tw_completed != rem_completed or tw_deleted > 0:
                status_issues.append(
                    (title, tw_pending, tw_completed, tw_deleted, rem_pending, rem_completed)
                )

        total_tw += len(tw_all)
        total_rem += len(rem_all)
        total_mismatch += len(mismatches)

        scope = f" ({proj})" if proj else ""

        if mismatches:
            click.echo()
            click.echo(f"Count mismatches{scope}:")
            for title, tc, rc in mismatches:
                click.echo(f"  {title}: TW={tc} Rem={rc}")

    if status_issues:
        click.echo()
        click.echo("Status mismatches:")
        for title, twp, twc, twd, remp, remc in status_issues:
            parts = []
            if twp != remp:
                parts.append(f"pending TW={twp} Rem={remp}")
            if twc != remc:
                parts.append(f"completed TW={twc} Rem={remc}")
            if twd:
                parts.append(f"deleted TW={twd}")
            click.echo(f"  {title}: {', '.join(parts)}")

    if total_mismatch == 0 and not status_issues:
        click.echo()
        click.echo("All counts and statuses match.")

    click.echo()
    click.echo(f"Total: TW={total_tw}, Rem={total_rem}, Mismatches={total_mismatch}")


@tw_group.command(name="edit")
@click.argument("pattern", nargs=-1, required=True)
def tw_edit(pattern):
    """Edit tasks matching pattern in editor."""
    pattern_str = " ".join(pattern)
    result = run(
        ["task", "rc.verbose=nothing", "rc.detection=off", "rc.defaultwidth=0", "all"]
    )
    if result.returncode != 0:
        raise SystemExit(1)

    uuid_re = re.compile(r"\b([0-9a-f]{8})\b")
    regex = re.compile(pattern_str, re.IGNORECASE)
    uuids = []
    for line in result.stdout.splitlines():
        if regex.search(line):
            m = uuid_re.search(line)
            if m:
                uuids.append(m.group(1))

    if not uuids:
        click.echo(f"No tasks matching '{pattern_str}'")
        return

    click.echo(f"Editing {len(uuids)} task(s)...")
    for uuid in uuids:
        subprocess.run(["task", "edit", uuid])


@tw_group.command(name="find")
@click.argument("pattern", nargs=-1, required=True)
def tw_find(pattern):
    """Search tasks by pattern and show details."""
    pattern_str = " ".join(pattern)
    result = run(
        ["task", "rc.verbose=nothing", "rc.detection=off", "rc.defaultwidth=0", "all"]
    )
    if result.returncode != 0:
        raise SystemExit(1)

    uuid_re = re.compile(r"\b([0-9a-f]{8})\b")
    regex = re.compile(pattern_str, re.IGNORECASE)
    uuids = []
    for line in result.stdout.splitlines():
        if regex.search(line):
            m = uuid_re.search(line)
            if m:
                uuids.append(m.group(1))

    if not uuids:
        click.echo(f"No tasks matching '{pattern_str}'")
        return

    for i, uuid in enumerate(uuids):
        if i > 0:
            click.echo("=" * 80)
        info = subprocess.run(
            ["task", uuid], stdout=subprocess.PIPE, text=True, stderr=subprocess.DEVNULL
        )
        if info.returncode == 0:
            click.echo(info.stdout, nl=False)


@tw_group.command(name="list")
def tw_list():
    """List pending tasks."""
    result = run(["task", "export", "rc.verbose=nothing"])
    if result.returncode != 0:
        raise SystemExit(1)

    nu_script = """
    $in | from json
    | where status == "pending"
    | select id project? description due? urgency tags?
    | sort-by -r urgency
    | table -i false
    """
    nu = subprocess.run(
        ["nu", "--stdin", "-c", nu_script],
        input=result.stdout,
        text=True,
    )
    if nu.returncode != 0:
        try:
            tasks = json.loads(result.stdout)
        except json.JSONDecodeError:
            click.echo("Failed to parse task export", err=True)
            raise SystemExit(1)

        pending = [t for t in tasks if t.get("status") == "pending"]
        pending.sort(key=lambda t: t.get("urgency", 0), reverse=True)

        if not pending:
            click.echo("No pending tasks")
            return

        fmt = "{:<4} {:<15} {:<50} {:<12} {:<8}"
        click.echo(fmt.format("ID", "Project", "Description", "Due", "Urgency"))
        click.echo("-" * 89)
        for t in pending:
            click.echo(
                fmt.format(
                    t.get("id", ""),
                    (t.get("project") or "")[:15],
                    (t.get("description") or "")[:50],
                    (t.get("due") or "")[:12],
                    f"{t.get('urgency', 0):.1f}",
                )
            )


@reminders_group.command(name="edit")
@click.argument("pattern", nargs=-1, required=True)
def rem_edit(pattern):
    """Edit reminders matching pattern in editor."""
    pattern_str = " ".join(pattern)
    result = run(
        ["rems", "show-all", "--include-completed", "--format", "json"]
    )
    if result.returncode != 0:
        click.echo("Failed to fetch reminders", err=True)
        raise SystemExit(1)

    try:
        all_reminders = json.loads(result.stdout)
    except json.JSONDecodeError:
        click.echo("Failed to parse reminders JSON", err=True)
        raise SystemExit(1)

    regex = re.compile(pattern_str, re.IGNORECASE)
    matches = [r for r in all_reminders if regex.search(r.get("title", ""))]

    if not matches:
        click.echo(f"No reminders matching '{pattern_str}'")
        return

    click.echo(f"Editing {len(matches)} reminder(s)...")
    for reminder in matches:
        original = json.loads(json.dumps(reminder))
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", delete=False
        ) as f:
            json.dump(reminder, f, indent=2, ensure_ascii=False)
            f.write("\n")
            tmp_path = f.name

        try:
            editor = os.environ.get("EDITOR", "nvim")
            subprocess.run([editor, tmp_path])

            with open(tmp_path) as f:
                edited = json.load(f)
        except (json.JSONDecodeError, OSError) as e:
            click.echo(f"Error reading edited file: {e}", err=True)
            continue
        finally:
            os.unlink(tmp_path)

        if edited == original:
            click.echo(f"  No changes for: {original.get('title', '')}")
            continue

        list_name = original["list"]
        ext_id = original["externalId"]
        cmd = ["rems", "edit", list_name, ext_id, "--include-completed"]

        if edited.get("title") != original.get("title"):
            cmd.append(edited["title"])
        if edited.get("notes") != original.get("notes"):
            cmd.extend(["--notes", edited.get("notes", "")])
        if edited.get("dueDate") != original.get("dueDate"):
            cmd.extend(["--due-date", edited.get("dueDate", "")])
        if edited.get("priority") != original.get("priority"):
            cmd.extend(["--priority", str(edited.get("priority", 0))])

        if len(cmd) > 5:
            subprocess.run(cmd)
            click.echo(f"  Updated: {edited.get('title', '')}")
        else:
            click.echo(f"  No supported field changes for: {original.get('title', '')}")


@reminders_group.command(name="find")
@click.argument("pattern", nargs=-1, required=True)
def rem_find(pattern):
    """Search reminders by pattern."""
    pattern_str = " ".join(pattern)
    result = run(
        ["rems", "show-all", "--include-completed", "--format", "json"]
    )
    if result.returncode != 0:
        click.echo("Failed to fetch reminders", err=True)
        raise SystemExit(1)

    try:
        reminders = json.loads(result.stdout)
    except json.JSONDecodeError:
        click.echo("Failed to parse reminders JSON", err=True)
        raise SystemExit(1)

    regex = re.compile(pattern_str, re.IGNORECASE)
    matches = [r for r in reminders if regex.search(r.get("title", ""))]

    if not matches:
        click.echo(f"No reminders matching '{pattern_str}'")
        return

    for i, r in enumerate(matches):
        if i > 0:
            click.echo("=" * 80)
        click.echo(json.dumps(r, indent=2, ensure_ascii=False))


@reminders_group.command(name="list")
def rem_list():
    """List reminders."""
    result = run(["rems", "show-all", "--format", "json"])
    if result.returncode != 0:
        click.echo("Failed to fetch reminders", err=True)
        raise SystemExit(1)

    try:
        reminders = json.loads(result.stdout)
    except json.JSONDecodeError:
        click.echo("Failed to parse reminders JSON", err=True)
        raise SystemExit(1)

    if not reminders:
        click.echo("No reminders")
        return

    for r in reminders:
        status = "done" if r.get("isCompleted") else "pending"
        due = r.get("dueDate", "")
        title = r.get("title", "")
        list_name = r.get("list", "")
        click.echo(f"[{status}] [{list_name}] {title}  due: {due}")


if __name__ == "__main__":
    cli(prog_name="taskmanager")
