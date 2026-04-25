"""Click CLI command groups and all commands."""

import json
import os
import re
import shlex
import subprocess
import tempfile
from collections import Counter, defaultdict

import click

import utils
from backends import (
    find_tw_uuids,
    get_reminders,
    get_tw_tasks,
    list_reminder_lists,
)
from display import (
    print_drift,
)
from matching import compute_drift
from sync import (
    filter_by_recurring,
    filter_by_title,
    filter_metadata_diffs,
    sync_metadata,
)
from utils import (
    PRIORITY_LABEL,
    REMINDERS_PRIORITY_MAP,
    TW_TO_REMINDERS_PRIORITY,
    date_key,
    format_date_local,
    has_command,
    is_darwin,
    normalize_system_name,
    parse_projects,
    prefixed_title,
    run,
    tw_date_to_iso,
)


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
                                child_help = child.get_short_help_str(
                                    limit=formatter.width
                                )
                                formatter.write(f"    {child_name:<8}{child_help}\n")


@click.group(cls=TreeGroup)
@click.option(
    "--prefix/--no-prefix",
    default=False,
    help="Prefix descriptions with 'Project: ' (default: no prefix).",
)
def cli(prefix):
    """Unified task management across Apple Reminders and Taskwarrior."""
    utils._prefix_mode = prefix


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


# ---------------------------------------------------------------------------
# reminders sort
# ---------------------------------------------------------------------------


@reminders_group.command(name="sort")
@click.option("--source", default=None, help="Limit to a single source list.")
@click.option(
    "--approve", is_flag=True, default=False, help="Skip all confirmation prompts."
)
@click.option(
    "--interactive", is_flag=True, default=False, help="Confirm each item individually."
)
@click.option("--verbose", is_flag=True, default=False, help="Show commands being run.")
def sort_reminders(source, approve, interactive, verbose):
    """Sort reminders into their matching lists (requires --prefix mode).

    In --prefix mode, scans all lists for items whose '<Prefix>: ' doesn't
    match the current list and moves them to the correct one. Also adds the
    list prefix to reminders that are missing it. Use --source to limit to
    one list.
    """
    utils._verbose = verbose

    if not utils._prefix_mode:
        return

    if not (is_darwin() and has_command("rems")):
        click.echo("Error: reminders CLI not available", err=True)
        raise SystemExit(1)

    # Get all existing list names
    existing_lists = set(list_reminder_lists())
    if not existing_lists:
        click.echo("No reminder lists found.", err=True)
        return

    lists_to_scan = [source] if source else sorted(existing_lists)

    # Collect moves and prefix additions across all scanned lists
    moves = []
    prefix_adds = []
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
                # Item has no prefix — add list prefix
                if title.strip():
                    prefix_adds.append(
                        {
                            "source": list_name,
                            "index": i,
                            "title": title,
                            "external_id": item.get("externalId", ""),
                        }
                    )
                continue
            prefix, rest = title.split(": ", 1)
            if not rest.strip():
                continue
            target_list = prefix
            # Skip if already in the correct list
            if target_list == list_name:
                continue
            # Only move to existing lists
            if target_list not in existing_lists:
                if utils._verbose:
                    click.echo(f"  skip (no list): {title}", err=True)
                continue
            moves.append(
                {
                    "source": list_name,
                    "index": i,
                    "title": title,
                    "target": target_list,
                    "external_id": item.get("externalId", ""),
                }
            )

    if not moves and not prefix_adds:
        return

    if prefix_adds:
        click.echo()
        click.echo(f"{len(prefix_adds)} reminder(s) missing list prefix:")
        click.echo()
        for p in prefix_adds:
            click.echo(f"  {p['title']}")
            click.echo(f"    \u2192 {p['source']}: {p['title']}")

        if not approve:
            click.echo()
            if not click.confirm("Add prefixes?"):
                prefix_adds = []

        prefixed_count = 0
        for p in prefix_adds:
            new_title = f"{p['source']}: {p['title']}"
            if interactive:
                click.echo()
                click.echo(f"  {p['title']}")
                click.echo(f"    \u2192 {new_title}")
                if not click.confirm("  Add prefix?"):
                    continue

            lookup = p["external_id"] if p["external_id"] else str(p["index"])
            res = run(["rems", "edit", p["source"], lookup, "--", new_title])
            if res.returncode == 0:
                prefixed_count += 1
                click.echo(f"  Prefixed: {new_title}")
            else:
                click.echo(f"  ERROR prefixing: {p['title']}", err=True)

        if prefix_adds:
            click.echo()
            click.echo(
                f"Done. Prefixed {prefixed_count}/{len(prefix_adds)} reminder(s)."
            )

    if not moves:
        return

    # Display plan
    click.echo()
    click.echo(f"{len(moves)} item(s) to move:")
    click.echo()
    for m in moves:
        click.echo(f"  {m['source']}: {m['title']}")
        click.echo(f"    \u2192 {m['target']}")

    if not approve:
        click.echo()
        if not click.confirm("Proceed?"):
            click.echo("Aborted.")
            return

    # Execute moves in reverse index order to avoid index shifting
    moved = 0
    for m in reversed(moves):
        target = m["target"]

        if interactive:
            click.echo()
            click.echo(f"  {m['title']}")
            click.echo(f"    \u2192 {target}")
            if not click.confirm("  Move?"):
                continue

        # Move the item (use externalId if available, else index)
        lookup = m["external_id"] if m["external_id"] else str(m["index"])
        res = run(["rems", "move", m["source"], lookup, target])
        if res.returncode != 0:
            click.echo(f"  ERROR moving: {m['title']}", err=True)
            continue

        moved += 1
        click.echo(f"  Moved: {m['source']}: {m['title']} \u2192 {target}")

    click.echo()
    click.echo(f"Done. Moved {moved}/{len(moves)} item(s).")


# ---------------------------------------------------------------------------
# taskwarrior sort
# ---------------------------------------------------------------------------


@tw_group.command(name="sort")
@click.option("--project", default=None, help="Limit to a single project.")
@click.option(
    "--approve", is_flag=True, default=False, help="Skip all confirmation prompts."
)
@click.option(
    "--interactive", is_flag=True, default=False, help="Confirm each item individually."
)
@click.option("--verbose", is_flag=True, default=False, help="Show commands being run.")
def sort_tw(project, approve, interactive, verbose):
    """Sort TW tasks into their matching projects (requires --prefix mode).

    In --prefix mode, scans all tasks (or a single --project) for items whose
    '<Prefix>: ' doesn't match the current project and moves them to the
    correct one. Also adds the project prefix to tasks that are missing it.
    """
    utils._verbose = verbose

    if not utils._prefix_mode:
        return

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
    prefix_adds = []

    for task in tasks:
        if task.get("status") == "recurring":
            continue
        desc = task.get("description", "")
        current_project = task.get("project", "")
        uuid = task.get("uuid", "")
        if ": " not in desc:
            # Task has no prefix — add project prefix
            if current_project and desc.strip():
                prefix_adds.append(
                    {
                        "uuid": uuid,
                        "description": desc,
                        "project": current_project,
                    }
                )
            continue
        prefix, rest = desc.split(": ", 1)
        if not rest.strip():
            continue
        target_project = prefix
        if target_project == current_project:
            continue
        moves.append(
            {
                "uuid": uuid,
                "description": desc,
                "current_project": current_project,
                "target_project": target_project,
            }
        )

    if not moves and not prefix_adds:
        return

    if prefix_adds:
        click.echo()
        click.echo(f"{len(prefix_adds)} task(s) missing project prefix:")
        click.echo()
        for p in prefix_adds:
            click.echo(f"  {p['description']}")
            click.echo(f"    \u2192 {p['project']}: {p['description']}")

        if not approve:
            click.echo()
            if not click.confirm("Add prefixes?"):
                prefix_adds = []

        prefixed_count = 0
        for p in prefix_adds:
            prefixed_desc = f"{p['project']}: {p['description']}"
            if interactive:
                click.echo()
                click.echo(f"  {p['description']}")
                click.echo(f"    \u2192 {prefixed_desc}")
                if not click.confirm("  Add prefix?"):
                    continue

            res = run(
                [
                    "task",
                    "rc.confirmation:off",
                    p["uuid"],
                    "modify",
                    f"description:{prefixed_desc}",
                ]
            )
            if res.returncode == 0:
                prefixed_count += 1
                click.echo(f"  Prefixed: {prefixed_desc}")
            else:
                click.echo(f"  ERROR prefixing: {p['description']}", err=True)

        if prefix_adds:
            click.echo()
            click.echo(f"Done. Prefixed {prefixed_count}/{len(prefix_adds)} task(s).")

    if moves:
        click.echo()
        click.echo(f"{len(moves)} task(s) to move:")
        click.echo()
        for m in moves:
            src = m["current_project"] or "(no project)"
            click.echo(f"  {src}: {m['description']}")
            click.echo(f"    \u2192 project:{m['target_project']}")

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
                click.echo(f"    \u2192 project:{m['target_project']}")
                if not click.confirm("  Move?"):
                    continue

            res = run(
                [
                    "task",
                    "rc.confirmation:off",
                    m["uuid"],
                    "modify",
                    f"project:{m['target_project']}",
                ]
            )
            if res.returncode == 0:
                moved += 1
                click.echo(
                    f"  Moved: {m['description']} \u2192 project:{m['target_project']}"
                )
            else:
                click.echo(f"  ERROR moving: {m['description']}", err=True)

        click.echo()
        click.echo(f"Done. Moved {moved}/{len(moves)} task(s).")


# ---------------------------------------------------------------------------
# all sort
# ---------------------------------------------------------------------------


@all_cmds.command(name="sort")
@click.option("--source", default=None, help="Limit Reminders to a single source list.")
@click.option("--project", default=None, help="Limit Taskwarrior to a single project.")
@click.option(
    "--approve", is_flag=True, default=False, help="Skip all confirmation prompts."
)
@click.option(
    "--interactive", is_flag=True, default=False, help="Confirm each item individually."
)
@click.option("--verbose", is_flag=True, default=False, help="Show commands being run.")
@click.pass_context
def sort_all(ctx, source, project, approve, interactive, verbose):
    """Sort items in both Reminders and Taskwarrior by list/project."""
    utils._verbose = verbose

    if is_darwin() and has_command("rems"):
        ctx.invoke(
            sort_reminders,
            source=source,
            approve=approve,
            interactive=interactive,
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


# ---------------------------------------------------------------------------
# all drift
# ---------------------------------------------------------------------------


@all_cmds.command()
@click.option("--project", default=None, help="Scope to a single project/list.")
@click.option("--projects", default=None, help="Comma-separated project/list names.")
@click.option(
    "--filter", default=None, help="Filter to items matching title substring."
)
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
@click.option(
    "--sort-first/--no-sort-first",
    default=True,
    help="Run sort before computing drift (default: enabled).",
)
@click.pass_context
def drift(
    ctx,
    project,
    projects,
    filter,
    notes,
    recurring,
    source,
    destination,
    verbose,
    sort_first,
):
    """Show drift between Reminders and Taskwarrior."""
    utils._verbose = verbose

    if sort_first:
        ctx.invoke(
            sort_all,
            source=None,
            project=project,
            approve=False,
            interactive=False,
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


# ---------------------------------------------------------------------------
# all sync
# ---------------------------------------------------------------------------


@all_cmds.command()
@click.option("--project", default=None, help="Scope to a single project/list.")
@click.option("--projects", default=None, help="Comma-separated project/list names.")
@click.option(
    "--filter", default=None, help="Filter to items matching title substring."
)
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
    help="Mark TW-only duplicates as deleted (status:deleted, no purge). Always interactive.",
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
    help="Mark TW recurring parents (and child instances) as deleted. Always interactive. Does not call `task purge` to avoid orphan ops in TaskChampion.",
)
@click.option(
    "--sort-first/--no-sort-first",
    default=True,
    help="Run sort before syncing (default: enabled).",
)
@click.pass_context
def sync(
    ctx,
    project,
    projects,
    filter,
    approve,
    interactive,
    notes,
    recurring,
    source,
    destination,
    verbose,
    purge_duplicates,
    complete_orphans,
    purge_recurring,
    sort_first,
):
    """Sync missing items to both systems."""
    utils._verbose = verbose

    if sort_first:
        ctx.invoke(
            sort_all,
            source=None,
            project=project,
            approve=False,
            interactive=False,
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
    if (
        total == 0
        and not purge_duplicates
        and not complete_orphans
        and not purge_recurring
    ):
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

    # Reminders-only -> add to Taskwarrior
    for item in rem_only.values():
        proj = item["project"]
        desc = prefixed_title(proj, item["title"])
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
            rem_url = (item.get("url") or "").strip()
            if rem_url:
                click.echo(f"    url: {rem_url}")
            rem_prio = REMINDERS_PRIORITY_MAP.get(item.get("priority", 0), "")
            if rem_prio:
                click.echo(f"    priority: {PRIORITY_LABEL.get(rem_prio, rem_prio)}")
            if not click.confirm("  Copy to Taskwarrior?"):
                continue
        # Check if a pending TW task with the same title already exists (avoid duplicates)
        existing_uuids = find_tw_uuids(proj, item["title"], status_filter="pending")
        if existing_uuids and item["status"] == "completed":
            # Complete the existing task instead of creating a duplicate
            uuid = existing_uuids[0]
            run(["task", "rc.confirmation:off", uuid, "done"])
            click.echo(f"  ~ Taskwarrior: {desc} (completed existing)")
            raw_end = item.get("completionDate", "")
            if raw_end:
                run(["task", "rc.confirmation:off", uuid, "modify", f"end:{raw_end}"])
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
                run(["task", "rc.confirmation:off", uuid, "modify"] + mods)
            # Fetch existing annotations to avoid duplicates
            existing_anns = set()
            find = subprocess.run(
                ["task", uuid, "export"], capture_output=True, text=True
            )
            if find.returncode == 0:
                try:
                    exported = json.loads(find.stdout)
                    if exported:
                        existing_anns = {
                            a.get("description", "").strip()
                            for a in exported[0].get("annotations", [])
                        }
                except json.JSONDecodeError:
                    pass
            item_notes = (item.get("notes") or "").strip()
            if item_notes and item_notes not in existing_anns:
                run(["task", uuid, "annotate", item_notes])
            item_url = (item.get("url") or "").strip()
            if item_url and item_url != item_notes and item_url not in existing_anns:
                run(["task", uuid, "annotate", item_url])
            click.echo(f"  ~ Taskwarrior: {desc} (updated existing)")
        else:
            add_cmd = ["task", "add", desc, f"project:{proj}"]

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
                click.echo(f"  + Taskwarrior: {desc}")

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
                    # Notes -> annotation
                    item_notes = (item.get("notes") or "").strip()
                    if item_notes:
                        run(["task", uuid, "annotate", item_notes])

                    # URL -> separate annotation (skip if identical to notes)
                    item_url = (item.get("url") or "").strip()
                    if item_url and item_url != item_notes:
                        run(["task", uuid, "annotate", item_url])

                    # Creation date
                    raw_created = item.get("creationDate", "")
                    if raw_created:
                        run(
                            [
                                "task",
                                "rc.confirmation:off",
                                uuid,
                                "modify",
                                f"entry:{raw_created}",
                            ]
                        )

                    # Completion date + status
                    if item["status"] == "completed":
                        run(["task", "rc.confirmation:off", uuid, "done"])
                    raw_end = item.get("completionDate", "")
                    if raw_end:
                        run(
                            [
                                "task",
                                "rc.confirmation:off",
                                uuid,
                                "modify",
                                f"end:{raw_end}",
                            ]
                        )

    # Taskwarrior-only -> add to Reminders
    if is_darwin() and has_command("rems"):
        existing_lists = set(list_reminder_lists())

        for item in tw_only.values():
            proj = item["project"]
            desc = prefixed_title(proj, item["title"])

            # Never copy deleted TW tasks to Reminders
            if item.get("status") == "deleted":
                continue
            # Skip tasks with no project — cannot determine target list
            if not proj:
                if interactive:
                    click.echo()
                    click.echo(f"Skipping (no project): {item['title']}")
                continue
            # Skip TW->Rem copy when --complete-orphans or --purge-duplicates will handle them
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
                run(["rems", "lists", "new", proj])
                existing_lists.add(proj)

            add_cmd = ["rems", "add", proj]

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
                add_cmd.append(f"--notes={notes_text}")

            # Keep positional reminder text after all options so titles
            # beginning with "-" are not parsed as flags.
            add_cmd.extend(["--", desc])

            result = run(add_cmd)
            if result.returncode == 0:
                click.echo(f"  + Reminders: {desc}")
                if item["status"] == "completed":
                    complete_cmd = ["rems", "complete", proj]
                    raw_end = item.get("end", "")
                    if raw_end:
                        complete_cmd.extend(
                            ["--completion-date", tw_date_to_iso(raw_end)]
                        )
                    complete_cmd.extend(["--", desc])
                    run(complete_cmd)

    # Sync metadata for matched items with drift
    if metadata_diffs:
        meta_count = sync_metadata(
            metadata_diffs, direction=source, interactive=interactive
        )
        if meta_count:
            click.echo()
            click.echo(f"Updated metadata on {meta_count} items.")

    # Purge TW duplicates (always interactive, requires explicit confirmation)
    # Detects both TW-only items and TW-internal duplicates (multiple pending
    # tasks with the same project+description).
    if purge_duplicates:
        delete_count = 0

        # 1. TW-only items with no Reminders counterpart
        if tw_only:
            click.echo()
            click.echo(f"--- TW-only items ({len(tw_only)}) ---")
            for key, item in tw_only.items():
                proj = item["project"]
                desc = prefixed_title(proj, item["title"])
                uuid = item.get("uuid", "")
                due = format_date_local(item.get("due", ""))
                status = item.get("status", "pending")
                click.echo()
                click.echo(f"  TW-only: {desc}")
                click.echo(f"    status: {status}")
                if due:
                    click.echo(f"    due: {due}")
                if uuid:
                    click.echo(f"    uuid: {uuid[:8]}")
                if not click.confirm("  DELETE from Taskwarrior?", default=False):
                    continue
                if uuid:
                    if status == "deleted":
                        # Already marked deleted — nothing to do. We deliberately
                        # do not call `task purge` here: TaskChampion writes a
                        # raw Delete op into the operations table for each purge,
                        # and any divergence with the tasks table corrupts the
                        # store (every `task` invocation then hard-crashes with
                        # "Invalid column type Text at index: 0, name: data").
                        # Run `task purge` manually if true GC is desired.
                        click.echo(f"  - Taskwarrior: {desc} (already deleted)")
                        continue
                    result = run(["task", "rc.confirmation:off", uuid, "delete"])
                    if result.returncode == 0:
                        click.echo(f"  - Taskwarrior: {desc} (deleted)")
                        delete_count += 1
                    else:
                        click.echo(f"  ! Failed to delete: {desc}")

        # 2. TW-internal duplicates: multiple pending tasks with same description
        click.echo()
        click.echo("--- Scanning for TW-internal duplicates ---")

        tw_cmd = ["task"]
        for proj in (
            parse_projects(projects) if projects else [project] if project else []
        ):
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
                ann_texts = tuple(
                    sorted(a.get("description", "") for a in t.get("annotations", []))
                )
                return (
                    t.get("description", ""),
                    t.get("project", ""),
                    date_key(t.get("due", "")),
                    t.get("priority", ""),
                    ann_texts,
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
                    click.echo(
                        f"    keeping: uuid:{keep['uuid'][:8]} entry:{keep.get('entry', '')[:10]}"
                    )
                    for d in dupes:
                        entry = d.get("entry", "")[:10]
                        click.echo(f"    duplicate: uuid:{d['uuid'][:8]} entry:{entry}")
                        if not click.confirm(
                            "    DELETE this duplicate?", default=False
                        ):
                            continue
                        result = run(
                            ["task", "rc.confirmation:off", d["uuid"], "delete"]
                        )
                        if result.returncode == 0:
                            click.echo(f"    - Deleted {d['uuid'][:8]}")
                            delete_count += 1
                            dup_count += 1
                        else:
                            click.echo(f"    ! Failed to delete {d['uuid'][:8]}")
            if dup_count == 0:
                click.echo("  No internal duplicates found.")

        if delete_count:
            click.echo()
            click.echo(f"Deleted {delete_count} TW duplicate(s).")

    # Complete TW-only pending orphans that have completed history
    if complete_orphans and tw_only:
        click.echo()
        click.echo(f"--- TW-only pending orphans ({len(tw_only)} items) ---")
        complete_count = 0
        for key, item in tw_only.items():
            if item.get("status") != "pending":
                continue
            proj = item["project"]
            desc = prefixed_title(proj, item["title"])
            title = item["title"]
            uuid = item.get("uuid", "")
            if not uuid:
                continue
            # Check if this title has completed history in TW
            all_uuids_result = subprocess.run(
                ["task", f"project.is:{proj}", "export"],
                capture_output=True,
                text=True,
            )
            has_completed = False
            legacy_prefixed = f"{proj}: {title}"
            if all_uuids_result.returncode == 0:
                try:
                    for t in json.loads(all_uuids_result.stdout):
                        t_desc = t.get("description", "")
                        if (t_desc == title or t_desc == legacy_prefixed) and t.get(
                            "status"
                        ) == "completed":
                            has_completed = True
                            break
                except json.JSONDecodeError:
                    pass
            if not has_completed:
                continue
            click.echo()
            click.echo(f"  TW orphan: {desc}")
            click.echo(f"    uuid: {uuid[:8]}")
            click.echo("    has completed history in TW")
            if not click.confirm("  COMPLETE this task?", default=False):
                continue
            result = run(["task", "rc.confirmation:off", uuid, "done"])
            if result.returncode == 0:
                click.echo(f"  ~ Completed: {desc}")
                complete_count += 1
            else:
                click.echo(f"  ! Failed to complete: {desc}")
        if complete_count:
            click.echo()
            click.echo(f"Completed {complete_count} orphan(s).")

    # Purge TW recurring parent tasks
    if purge_recurring:
        click.echo()
        click.echo("--- Scanning for TW recurring parents ---")
        tw_cmd = ["task", "export"]
        tw_result = subprocess.run(tw_cmd, capture_output=True, text=True)
        delete_count = 0
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
                    recurring_parents = [
                        t for t in recurring_parents if t.get("project", "") in proj_set
                    ]
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
                if not click.confirm(
                    "  DELETE this recurring parent (and children)?", default=False
                ):
                    continue
                # Find and delete child instances first
                children = [
                    c
                    for c in all_tw
                    if c.get("parent") == uuid and c.get("status") != "deleted"
                ]
                # Mark children + parent deleted, but do NOT call `task purge`.
                # TaskChampion writes a raw Delete op per purge into the
                # operations table; any divergence between operations and the
                # tasks table corrupts the store ("Invalid column type Text at
                # index: 0, name: data") and bricks every `task` invocation.
                # Run `task purge` manually later if real GC is desired.
                child_failed = False
                for child in children:
                    cres = run(["task", "rc.confirmation:off", child["uuid"], "delete"])
                    if cres.returncode != 0:
                        child_failed = True
                        click.echo(
                            f"  ! Failed to delete child {child['uuid'][:8]}; "
                            f"skipping parent delete to avoid orphaned children",
                            err=True,
                        )
                        break
                if child_failed:
                    continue
                result = run(["task", "rc.confirmation:off", uuid, "delete"])
                if result.returncode == 0:
                    click.echo(
                        f"  - Deleted: {desc} (+ {len(children)} child instance(s))"
                    )
                    delete_count += 1
                else:
                    click.echo(f"  ! Failed to delete: {desc}")
        if delete_count:
            click.echo()
            click.echo(f"Deleted {delete_count} recurring parent(s).")

    click.echo()
    click.echo("Done.")


# ---------------------------------------------------------------------------
# all verify
# ---------------------------------------------------------------------------


@all_cmds.command()
@click.option("--project", default=None, help="Scope to a single project/list.")
@click.option("--projects", default=None, help="Comma-separated project/list names.")
@click.option("--verbose", is_flag=True, default=False, help="Show commands being run.")
def verify(project, projects, verbose):
    """Verify item counts and statuses match between Reminders and Taskwarrior."""
    utils._verbose = verbose

    project_list = parse_projects(projects) if projects else [project]

    total_tw = 0
    total_rem = 0
    total_mismatch = 0
    status_issues = []

    for proj in project_list:
        tw_tasks, tw_counts, tw_instances = get_tw_tasks(proj, include_deleted=True)
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

            if (
                tw_pending != rem_pending
                or tw_completed != rem_completed
                or tw_deleted > 0
            ):
                status_issues.append(
                    (
                        title,
                        tw_pending,
                        tw_completed,
                        tw_deleted,
                        rem_pending,
                        rem_completed,
                    )
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


# ---------------------------------------------------------------------------
# taskwarrior edit/find/list
# ---------------------------------------------------------------------------


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
    try:
        nu = subprocess.run(
            ["nu", "--stdin", "-c", nu_script],
            input=result.stdout,
            text=True,
        )
    except FileNotFoundError:
        nu = None
    if nu is None or nu.returncode != 0:
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


@tw_group.command(name="ingest")
@click.option(
    "--project", "-p", default=None, help="Only ingest from this Reminders list."
)
@click.option("--approve", "-y", is_flag=True, help="Auto-approve all migrations.")
@click.option("--dry-run", "-n", is_flag=True, help="Preview without making changes.")
@click.option("--verbose", "-v", is_flag=True, help="Show commands being run.")
def tw_ingest(project, approve, dry_run, verbose):
    """Fetch pending reminders, create TW tasks, then delete the reminders."""
    utils._verbose = verbose

    if not (is_darwin() and has_command("rems")):
        click.echo("rems not available (macOS only)", err=True)
        raise SystemExit(1)

    # Fetch raw items to preserve duplicates with the same title
    _, _, all_instances = get_reminders(project_filter=project, include_completed=False)

    # Flatten all instances into a single list
    items = []
    for instance_list in all_instances.values():
        items.extend(instance_list)

    if not items:
        click.echo("No pending reminders to ingest.")
        return

    click.echo(f"Found {len(items)} pending reminder(s).")
    migrated = 0

    for item in items:
        proj = item["project"]
        title = item["title"]
        desc = prefixed_title(proj, title)

        click.echo()
        click.echo(f"  {proj}: {title}")
        rem_due = format_date_local(item.get("due", ""))
        if rem_due:
            click.echo(f"    due: {rem_due}")
        rem_notes = (item.get("notes") or "").strip()
        if rem_notes:
            click.echo(f"    notes: {repr(rem_notes)}")
        rem_prio = REMINDERS_PRIORITY_MAP.get(item.get("priority", 0), "")
        if rem_prio:
            click.echo(f"    priority: {PRIORITY_LABEL.get(rem_prio, rem_prio)}")

        if dry_run:
            click.echo("  [dry-run] Would create TW task and delete reminder")
            migrated += 1
            continue

        if not approve:
            if not click.confirm("  Migrate to Taskwarrior and delete reminder?"):
                continue

        # Always create a new TW task (each reminder becomes its own task)
        add_cmd = [
            "task",
            "rc.color:off",
            "add",
            desc,
            f"project:{proj}",
        ]
        raw_due = item.get("due", "")
        if raw_due:
            add_cmd.append(f"due:{raw_due}")
        tw_prio = REMINDERS_PRIORITY_MAP.get(item.get("priority", 0), "")
        if tw_prio:
            add_cmd.append(f"priority:{tw_prio}")

        result = run(add_cmd)
        if result.returncode != 0:
            click.echo(f"  ! Failed to create TW task for: {desc}", err=True)
            continue

        click.echo(f"  + Taskwarrior: {desc}")

        # Find UUID of newly created task for annotations/metadata
        # Strip ANSI codes in case rc.color:off is overridden
        clean_stdout = re.sub(r"\x1b\[[0-9;]*m", "", result.stdout)
        task_id_match = re.search(r"Created task (\d+)\.", clean_stdout)
        uuid = ""
        if task_id_match:
            tid = task_id_match.group(1)
            find = subprocess.run(
                ["task", tid, "export"], capture_output=True, text=True
            )
            if find.returncode == 0:
                try:
                    exported = json.loads(find.stdout)
                    if exported:
                        uuid = exported[0].get("uuid", "")
                except json.JSONDecodeError:
                    pass

        if not uuid and (rem_notes or item.get("creationDate", "")):
            click.echo(
                f"  ! Could not resolve TW task UUID, skipping metadata/delete: {desc}",
                err=True,
            )
            continue

        if uuid:
            if rem_notes:
                res = run(["task", uuid, "annotate", rem_notes])
                if res.returncode != 0:
                    click.echo(
                        f"  ! Failed to annotate TW task, skipping delete: {desc}",
                        err=True,
                    )
                    continue
            rem_url = (item.get("url") or "").strip()
            if rem_url and rem_url != rem_notes:
                run(["task", uuid, "annotate", rem_url])
            raw_created = item.get("creationDate", "")
            if raw_created:
                run(
                    [
                        "task",
                        "rc.confirmation:off",
                        uuid,
                        "modify",
                        f"entry:{raw_created}",
                    ]
                )

        # Delete the source reminder by externalId for instance-safe deletion
        ext_id = item.get("externalId", "")
        if ext_id:
            del_result = run(["rems", "delete", proj, "--force", "--", ext_id])
            if del_result.returncode == 0:
                click.echo(f"  - Reminder deleted: {title}")
                migrated += 1
            else:
                click.echo(f"  ! Failed to delete reminder: {title}", err=True)
        else:
            click.echo(f"  ! No externalId for reminder: {title}", err=True)

    click.echo()
    click.echo(f"Ingested {migrated} reminder(s).")


# ---------------------------------------------------------------------------
# reminders edit/find/list
# ---------------------------------------------------------------------------


@reminders_group.command(name="edit")
@click.argument("pattern", nargs=-1, required=True)
def rem_edit(pattern):
    """Edit reminders matching pattern in editor."""
    pattern_str = " ".join(pattern)
    result = run(["rems", "show", "--include-completed", "--format", "json"])
    if result.returncode != 0:
        click.echo("Failed to fetch reminders", err=True)
        raise SystemExit(1)

    try:
        all_reminders = json.loads(result.stdout)
    except json.JSONDecodeError:
        click.echo("Failed to parse reminders JSON", err=True)
        raise SystemExit(1)

    try:
        regex = re.compile(pattern_str, re.IGNORECASE)
    except re.error as e:
        click.echo(f"Invalid regex '{pattern_str}': {e}", err=True)
        raise SystemExit(1)
    matches = [r for r in all_reminders if regex.search(r.get("title", ""))]

    if not matches:
        click.echo(f"No reminders matching '{pattern_str}'")
        return

    click.echo(f"Editing {len(matches)} reminder(s)...")
    for reminder in matches:
        original = json.loads(json.dumps(reminder))
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump(reminder, f, indent=2, ensure_ascii=False)
            f.write("\n")
            tmp_path = f.name

        try:
            editor = os.environ.get("EDITOR", "nvim")
            subprocess.run(shlex.split(editor) + [tmp_path])

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
        has_field_change = False
        if edited.get("notes") != original.get("notes"):
            cmd.append(f"--notes={edited.get('notes', '')}")
            has_field_change = True
        if edited.get("dueDate") != original.get("dueDate"):
            cmd.extend(["--due-date", edited.get("dueDate", "")])
            has_field_change = True
        if edited.get("priority") != original.get("priority"):
            cmd.extend(["--priority", str(edited.get("priority", 0))])
            has_field_change = True
        if edited.get("title") != original.get("title"):
            has_field_change = True
        cmd.extend(["--", edited.get("title", original.get("title", ""))])

        if has_field_change:
            edit_result = subprocess.run(cmd, capture_output=True, text=True)
            if edit_result.returncode != 0:
                click.echo(
                    f"  ERROR editing: {edited.get('title', '')}: "
                    f"{edit_result.stderr.strip()}",
                    err=True,
                )
            else:
                click.echo(f"  Updated: {edited.get('title', '')}")
        else:
            click.echo(f"  No supported field changes for: {original.get('title', '')}")


@reminders_group.command(name="find")
@click.argument("pattern", nargs=-1, required=True)
def rem_find(pattern):
    """Search reminders by pattern."""
    pattern_str = " ".join(pattern)
    result = run(["rems", "show", "--include-completed", "--format", "json"])
    if result.returncode != 0:
        click.echo("Failed to fetch reminders", err=True)
        raise SystemExit(1)

    try:
        reminders = json.loads(result.stdout)
    except json.JSONDecodeError:
        click.echo("Failed to parse reminders JSON", err=True)
        raise SystemExit(1)

    try:
        regex = re.compile(pattern_str, re.IGNORECASE)
    except re.error as e:
        click.echo(f"Invalid regex '{pattern_str}': {e}", err=True)
        raise SystemExit(1)
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
    result = run(["rems", "show", "--format", "json"])
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
