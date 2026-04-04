"""Sync logic and filtering for drift resolution."""

import click

from backends import find_tw_uuids
from display import format_update_summary, print_drift_item
from utils import (
    REMINDERS_PRIORITY_MAP,
    REMINDERS_READ_ONLY_FIELDS,
    TW_TO_REMINDERS_PRIORITY,
    has_command,
    infer_flow,
    is_darwin,
    prefixed_title,
    run,
    tw_date_to_iso,
    tw_date_to_local_iso,
)


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


def sync_metadata(metadata_diffs, direction=None, interactive=False):
    """Sync metadata for matched items with drift. Returns count of updated items.

    direction: None=both ways, "reminders"=reminders->tw, "tw"=tw->reminders.
    """
    count = 0
    for (project, title), info in metadata_diffs.items():
        diffs = info["diffs"]
        tw = info["tw"]
        rem = info["rem"]
        desc = prefixed_title(project, title)

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
                longer_desc = prefixed_title(project, longer)
                if flow == "rem_to_tw":
                    tw_updates["title"] = longer_desc
                elif flow == "tw_to_rem":
                    rem_updates["title"] = longer_desc
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
            elif field == "url":
                if flow == "rem_to_tw":
                    rem_url = (rem.get("url") or "").strip()
                    if rem_url:
                        tw_updates["url"] = rem_url
                elif flow == "tw_to_rem":
                    pass  # TW stores URL as annotation; nothing to push back
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
                uuids = find_tw_uuids(project, tw["title"])
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
                    result = run(
                        ["task", "rc.confirmation:off", uuid, "modify"] + modify_args
                    )
                    # If modify fails on a recurring task (e.g. can't remove due),
                    # delete the recurring parent to stop recurrence, then retry
                    if result.returncode != 0 and tw.get("recur", ""):
                        click.echo(
                            "    Recurring task detected — purging to remove recurrence"
                        )
                        # Delete first if not already deleted, then purge
                        del_result = run(
                            ["task", "rc.confirmation:off", uuid, "delete"]
                        )
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
                if "url" in tw_updates:
                    notes_text = tw_updates.get("notes", "").strip()
                    if tw_updates["url"] != notes_text:
                        existing_anns = tw.get("annotations", [])
                        existing_texts = {
                            a.get("description", "").strip() for a in existing_anns
                        }
                        if tw_updates["url"] not in existing_texts:
                            run(["task", uuid, "annotate", tw_updates["url"]])
                if "status" in tw_updates:
                    if tw_updates["status"] == "completed":
                        run(["task", "rc.confirmation:off", uuid, "done"])
                        # Set end after done — task done overwrites end with now
                        if "end" in tw_updates:
                            run(
                                [
                                    "task",
                                    "rc.confirmation:off",
                                    uuid,
                                    "modify",
                                    f"end:{tw_updates['end']}",
                                ]
                            )
                    else:
                        run(
                            [
                                "task",
                                "rc.confirmation:off",
                                uuid,
                                "modify",
                                "status:pending",
                            ]
                        )
            if uuids:
                count += 1
                click.echo(
                    f"  ~ Taskwarrior: {desc}\n    {format_update_summary(tw_updates)}"
                )

        if rem_updates and is_darwin() and has_command("rems"):
            rem_desc = prefixed_title(project, rem["title"])
            rem_id = rem.get("externalId", "") or rem_desc
            edit_args = [
                "rems",
                "edit",
                project,
                rem_id,
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
                    complete_cmd = ["rems", "complete", project, rem_id]
                    raw_end = tw.get("end", "")
                    if raw_end:
                        complete_cmd.extend(
                            ["--completion-date", tw_date_to_iso(raw_end)]
                        )
                    run(complete_cmd)
                else:
                    run(["rems", "uncomplete", project, rem_id])
            count += 1
            click.echo(
                f"  ~ Reminders: {desc}\n    {format_update_summary(rem_updates)}"
            )

    return count


def filter_by_title(rem_only, tw_only, metadata_diffs, title_filter):
    """Filter drift results to items matching title substring."""
    if not title_filter:
        return rem_only, tw_only, metadata_diffs
    rem_only = {
        k: v for k, v in rem_only.items() if title_filter.lower() in k[1].lower()
    }
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
