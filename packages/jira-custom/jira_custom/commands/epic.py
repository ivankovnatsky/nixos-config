"""Epic commands for jira-custom."""

import click

from ..client import get_jira_client
from ..utils import ISSUE_KEY


def epic_list_fn(project=None, limit=50):
    """List epics in a project"""
    jira = get_jira_client()

    jql_parts = ["issuetype = Epic"]
    if project:
        jql_parts.append(f'project = "{project}"')

    jql = " AND ".join(jql_parts) + " ORDER BY created DESC"

    epics = jira.search_issues(jql, maxResults=limit)

    if not epics:
        click.echo("No epics found", err=True)
        return

    click.echo(f"{'KEY':<15} {'STATUS':<15} {'SUMMARY'}")
    click.echo("-" * 80)

    for epic in epics:
        key = epic.key
        status = epic.fields.status.name
        summary = epic.fields.summary
        if len(summary) > 45:
            summary = summary[:42] + "..."
        click.echo(f"{key:<15} {status:<15} {summary}")


def epic_create_fn(project, name, summary=None):
    """Create an epic"""
    jira = get_jira_client()

    fields = {
        "project": {"key": project},
        "summary": summary or name,
        "issuetype": {"name": "Epic"},
    }

    try:
        fields["customfield_10011"] = name
    except Exception:
        pass

    epic = jira.create_issue(fields=fields)
    click.echo(epic.key)


def epic_add_fn(epic_key, issue_keys):
    """Add issues to an epic"""
    jira = get_jira_client()

    epic = jira.issue(epic_key)
    jira.add_issues_to_epic(epic.id, list(issue_keys))

    click.echo(f"Added {len(issue_keys)} issue(s) to epic {epic_key}", err=True)
    for key in issue_keys:
        click.echo(f"  {key}")


def epic_remove_fn(issue_keys):
    """Remove issues from their epic"""
    jira = get_jira_client()

    for key in issue_keys:
        try:
            issue = jira.issue(key)
            issue.update(fields={"customfield_10014": None})
            click.echo(f"Removed {key} from epic", err=True)
        except Exception as e:
            click.echo(f"Error removing {key}: {e}", err=True)


@click.group("epic")
def epic_group():
    """Manage epics"""
    pass


@epic_group.command("list")
@click.option("-p", "--project", help="Project key")
@click.option("-l", "--limit", type=int, default=50, help="Max results")
def epic_list_cmd(project, limit):
    """List epics"""
    epic_list_fn(project, limit)


@epic_group.command("create")
@click.argument("project")
@click.option("-n", "--name", required=True, help="Epic name")
@click.option("-s", "--summary", help="Epic summary (defaults to name)")
def epic_create_cmd(project, name, summary):
    """Create an epic"""
    epic_create_fn(project, name, summary)


@epic_group.command("add")
@click.argument("epic_key", type=ISSUE_KEY)
@click.argument("issue_keys", nargs=-1, required=True, type=ISSUE_KEY)
def epic_add_cmd(epic_key, issue_keys):
    """Add issues to epic"""
    epic_add_fn(epic_key, issue_keys)


@epic_group.command("remove")
@click.argument("issue_keys", nargs=-1, required=True, type=ISSUE_KEY)
def epic_remove_cmd(issue_keys):
    """Remove issues from epic"""
    epic_remove_fn(issue_keys)
