"""Board commands for jira-custom."""

import os
import click
from rich.console import Console

from ..client import get_jira_client
from ..config import STATUS_DONE_JQL, STATUS_IN_PROGRESS
from ..display import render_board_table_fn


def resolve_board_by_name(jira, board_name):
    """Resolve board name to board ID"""
    boards = jira.boards()

    # Check for exact matches first
    exact_matches = [b for b in boards if b.name.lower() == board_name.lower()]
    if len(exact_matches) == 1:
        return str(exact_matches[0].id)
    elif len(exact_matches) > 1:
        names = ", ".join(f"{b.id} ({b.type})" for b in exact_matches)
        raise click.ClickException(
            f"Multiple boards named '{board_name}': {names}. Use --id instead."
        )

    # Try partial match
    matches = [b for b in boards if board_name.lower() in b.name.lower()]
    if len(matches) == 1:
        return str(matches[0].id)
    elif len(matches) > 1:
        names = ", ".join(f"'{b.name}' ({b.id}, {b.type})" for b in matches[:5])
        raise click.ClickException(f"Multiple boards match '{board_name}': {names}. Use --id instead.")

    raise click.ClickException(f"Board '{board_name}' not found")


def fetch_board_issues_fn(jira, board_id, show_done, limit):
    """Fetch issues from a board using agile API"""
    url = f"{jira._options['server']}/rest/agile/1.0/board/{board_id}/issue"
    params = {"maxResults": limit}
    if not show_done:
        status_list = ", ".join(f'"{s}"' for s in STATUS_DONE_JQL)
        params["jql"] = f"status NOT IN ({status_list})"

    response = jira._session.get(url, params=params)
    if response.status_code != 200:
        raise click.ClickException(f"Failed to get board issues: {response.status_code}")

    data = response.json()
    issue_keys = [i["key"] for i in data.get("issues", [])]
    if not issue_keys:
        return []

    jql = f"key in ({','.join(issue_keys)}) ORDER BY priority DESC, updated DESC"
    return jira.search_issues(jql, maxResults=limit)


def group_issues_by_status_fn(issues):
    """Group issues by status and return ordered columns

    Returns:
        tuple: (issues_by_status dict, all_columns list)
    """
    issues_by_status = {}
    for issue in issues:
        status = issue.fields.status.name
        if status not in issues_by_status:
            issues_by_status[status] = []
        issues_by_status[status].append(issue)

    # Kanban column order: TO DO -> BLOCKED -> IN PROGRESS
    kanban_columns = ["To Do", "Blocked", "In Progress"]

    # Merge Reopened into To Do
    if "Reopened" in issues_by_status:
        if "To Do" not in issues_by_status:
            issues_by_status["To Do"] = []
        issues_by_status["To Do"].extend(issues_by_status.pop("Reopened"))

    all_columns = kanban_columns + [s for s in issues_by_status.keys() if s not in kanban_columns]
    return issues_by_status, all_columns


def board_list_fn(project=None, board_type=None):
    """List boards"""
    jira = get_jira_client()

    boards = jira.boards(projectKeyOrID=project, type=board_type)

    if not boards:
        click.echo("No boards found", err=True)
        return

    click.echo(f"{'ID':<10} {'TYPE':<10} {'NAME'}")
    click.echo("-" * 60)

    for board in boards:
        board_id = board.id
        btype = board.type
        name = board.name
        click.echo(f"{board_id:<10} {btype:<10} {name}")


def board_view_fn(board_id=None, board_name=None, show_done=False, limit=100, my_in_progress=True):
    """View issues on a board with rich table formatting

    Args:
        my_in_progress: If True (default), only show current user's issues in In Progress column
    """
    jira = get_jira_client()
    current_user_email = os.getenv("JIRA_EMAIL")

    if board_name:
        board_id = resolve_board_by_name(jira, board_name)
    elif not board_id:
        board_id = os.getenv("JIRA_BOARD_ID")
        if not board_id:
            raise click.ClickException("Set JIRA_BOARD_ID or use --id/--name")

    console = Console()

    # Get board info for display
    try:
        board = jira.board(board_id)
        board_name = board.name
    except Exception:
        board_name = f"Board {board_id}"

    console.print()
    console.print(f"[bold cyan]{board_name}[/bold cyan]")

    # Fetch and process issues
    try:
        issues = fetch_board_issues_fn(jira, board_id, show_done, limit)
    except Exception as e:
        raise click.ClickException(f"Failed to get board issues: {e}")

    if not issues:
        console.print("[dim]No issues found[/dim]")
        return

    issues_by_status, all_columns = group_issues_by_status_fn(issues)

    # Filter In Progress to only show current user's issues by default
    if my_in_progress and current_user_email:
        for status in list(issues_by_status.keys()):
            if status.lower() in STATUS_IN_PROGRESS:
                issues_by_status[status] = [
                    issue for issue in issues_by_status[status]
                    if issue.fields.assignee and issue.fields.assignee.emailAddress == current_user_email
                ]

    if not all_columns:
        console.print("[dim]No status columns to display[/dim]")
        return

    render_board_table_fn(console, issues_by_status, all_columns)


@click.group("board")
def board_group():
    """Manage boards"""
    pass


@board_group.command("list")
@click.option("-p", "--project", help="Filter by project")
@click.option("-t", "--type", "board_type", type=click.Choice(["scrum", "kanban"]), help="Board type")
def board_list_cmd(project, board_type):
    """List boards"""
    board_list_fn(project, board_type)


@board_group.command("view")
@click.option("-b", "--id", "board_id", help="Board ID (or set JIRA_BOARD_ID)")
@click.option("-n", "--name", "board_name", help="Board name (partial match supported)")
@click.option("-a", "--all", "show_done", is_flag=True, help="Include Done/Resolved issues")
@click.option("--all-in-progress", "all_in_progress", is_flag=True, help="Show all In Progress issues (not just mine)")
@click.option("-l", "--limit", type=int, default=100, help="Max results (default: 100)")
def board_view_cmd(board_id, board_name, show_done, all_in_progress, limit):
    """View board issues in a table"""
    board_view_fn(board_id, board_name, show_done, limit, my_in_progress=not all_in_progress)
