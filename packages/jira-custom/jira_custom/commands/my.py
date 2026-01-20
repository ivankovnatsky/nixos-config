"""My issues command for jira-custom."""

import os
import click

from ..client import get_jira_client
from ..config import STATUS_DONE_JQL


def my_issues_fn(
    scope="sprint",
    project=None,
    exclude_done=True,
    priority=None,
    status=None,
    limit=50,
):
    """List issues assigned to current user"""
    jira = get_jira_client()
    email = os.getenv("JIRA_EMAIL")

    jql_parts = [f'assignee = "{email}"']

    if scope == "sprint":
        jql_parts.append("sprint in openSprints()")
    elif scope == "project" and project:
        jql_parts.append(f'project = "{project}"')

    if exclude_done:
        status_list = ", ".join(f'"{s}"' for s in STATUS_DONE_JQL)
        jql_parts.append(f"status NOT IN ({status_list})")

    if priority:
        jql_parts.append(f'priority = "{priority}"')

    if status:
        jql_parts.append(f'status = "{status}"')

    jql = " AND ".join(jql_parts) + " ORDER BY priority DESC, updated DESC"

    issues = jira.search_issues(jql, maxResults=limit)

    if not issues:
        click.echo("No issues found", err=True)
        return

    click.echo(f"{'KEY':<15} {'STATUS':<15} {'PRIORITY':<10} {'SUMMARY'}")
    click.echo("-" * 80)

    for issue in issues:
        key = issue.key
        status_name = issue.fields.status.name
        priority_name = issue.fields.priority.name if issue.fields.priority else "None"
        summary = issue.fields.summary
        if len(summary) > 45:
            summary = summary[:42] + "..."
        click.echo(f"{key:<15} {status_name:<15} {priority_name:<10} {summary}")


@click.command("my")
@click.argument("scope", type=click.Choice(["sprint", "project", "all"]), default="sprint")
@click.option("-p", "--project", help="Project key (required for 'project' scope)")
@click.option("-a", "--all-statuses", is_flag=True, help="Include done/closed issues")
@click.option("--priority", help="Filter by priority (e.g., High, Medium)")
@click.option("--status", help="Filter by status (e.g., 'In Progress')")
@click.option("-l", "--limit", type=int, default=50, help="Max results (default: 50)")
def my_cmd(scope, project, all_statuses, priority, status, limit):
    """List my issues"""
    my_issues_fn(scope, project, not all_statuses, priority, status, limit)
