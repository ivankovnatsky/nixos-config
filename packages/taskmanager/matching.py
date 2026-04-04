"""Instance matching, metadata comparison, and drift computation."""

import click

from backends import get_reminders, get_tw_tasks
from utils import (
    PRIORITY_LABEL,
    REMINDERS_PRIORITY_MAP,
    date_key,
    format_date_local,
)


def match_instances(tw_list, rem_list):
    """Match multi-instance items by due date.

    Two passes: first match same-status items (completed<->completed,
    pending<->pending), then cross-status. This prevents a pending item
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
                        tw_ann = "; ".join(
                            a.get("description", "")
                            for a in tw_item.get("annotations", [])
                        )
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
                if same_status and (
                    (tw_due and not rem_due) or (not tw_due and rem_due)
                ):
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
    tw_joined = "\n".join(tw_ann_texts)
    notes_equivalent = rem_notes == tw_joined
    if not notes_equivalent:
        if rem_notes and rem_notes not in tw_ann_texts:
            diffs.append(("notes", rem_notes_display, tw_notes_display))
        elif not rem_notes and tw_ann_texts:
            diffs.append(("notes", rem_notes_display, tw_notes_display))
        elif (
            rem_notes and tw_ann_texts and any(a not in rem_notes for a in tw_ann_texts)
        ):
            diffs.append(("notes", rem_notes_display, tw_notes_display))

    # URL — check if reminder URL exists as a TW annotation
    rem_url = (rem.get("url") or "").strip()
    if rem_url:
        tw_ann_has_url = any(
            a.get("description", "").strip() == rem_url for a in tw_annotations
        )
        if not tw_ann_has_url:
            diffs.append(("url", rem_url, "''"))

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
    import utils

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

    multi_instance = {k for k, c in tw_counts.items() if c > 1} | {
        k for k, c in rem_counts.items() if c > 1
    }

    # Handle multi-instance items via instance-level matching by due date
    instance_matched = set()
    instance_rem_only = {}
    instance_tw_only = {}
    instance_metadata_diffs = {}

    if multi_instance:
        if utils._verbose:
            click.echo(
                f"\nMatching {len(multi_instance)} recurring/multi-instance"
                " item(s) by due date...",
                err=True,
            )
        for key in sorted(multi_instance):
            if utils._verbose:
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
                due_display = (
                    format_date_local(tw_item.get("due", "") or rem_item.get("due", ""))
                    or due
                )
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
