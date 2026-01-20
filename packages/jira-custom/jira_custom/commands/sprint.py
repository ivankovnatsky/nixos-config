"""Sprint commands for jira-custom."""

import os
import click

from ..client import get_jira_client


def sprint_list_fn(board_id=None, state=None):
    """List sprints"""
    jira = get_jira_client()

    if not board_id:
        board_id = os.getenv("JIRA_BOARD_ID")
        if not board_id:
            raise click.ClickException("Set JIRA_BOARD_ID or use --board")

    sprints = jira.sprints(board_id, state=state)

    if not sprints:
        click.echo("No sprints found", err=True)
        return

    click.echo(f"{'ID':<10} {'STATE':<10} {'NAME':<40} {'START':<12} {'END':<12}")
    click.echo("-" * 90)

    for sprint in sprints:
        sprint_id = sprint.id
        sprint_state = sprint.state
        name = sprint.name[:38] + ".." if len(sprint.name) > 40 else sprint.name
        start = (
            getattr(sprint, "startDate", "N/A")[:10]
            if hasattr(sprint, "startDate") and sprint.startDate
            else "N/A"
        )
        end = (
            getattr(sprint, "endDate", "N/A")[:10]
            if hasattr(sprint, "endDate") and sprint.endDate
            else "N/A"
        )
        click.echo(f"{sprint_id:<10} {sprint_state:<10} {name:<40} {start:<12} {end:<12}")


def sprint_add_fn(sprint_id, issue_keys):
    """Add issues to a sprint"""
    jira = get_jira_client()

    jira.add_issues_to_sprint(sprint_id, list(issue_keys))

    click.echo(f"Added {len(issue_keys)} issue(s) to sprint {sprint_id}", err=True)
    for key in issue_keys:
        click.echo(f"  {key}")


@click.group("sprint")
def sprint_group():
    """Manage sprints"""
    pass


@sprint_group.command("list")
@click.option("-b", "--board", help="Board ID (or set JIRA_BOARD_ID)")
@click.option("-s", "--state", type=click.Choice(["future", "active", "closed"]), help="Filter by state")
@click.option("--current", is_flag=True, help="Show only active sprint")
def sprint_list_cmd(board, state, current):
    """List sprints"""
    state = "active" if current else state
    sprint_list_fn(board, state)


@sprint_group.command("add")
@click.argument("sprint_id")
@click.argument("issue_keys", nargs=-1, required=True)
def sprint_add_cmd(sprint_id, issue_keys):
    """Add issues to sprint"""
    sprint_add_fn(sprint_id, issue_keys)
