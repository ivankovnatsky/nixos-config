"""Issue commands for jira-custom."""

import os
import click

from ..client import get_jira_client
from ..utils import parse_labels, move_issue_type
from .comment import comment_group
from .transition import transition_group


def issue_create_fn(
    project,
    summary,
    issue_type="Task",
    description=None,
    parent=None,
    assignee=None,
    labels=None,
):
    """Create a new issue"""
    jira = get_jira_client()
    fields = {
        "project": {"key": project},
        "summary": summary,
        "issuetype": {"name": issue_type},
    }
    if description:
        fields["description"] = description
    if parent:
        fields["parent"] = {"key": parent}
    if assignee:
        fields["assignee"] = {"name": assignee}
    if labels:
        fields["labels"] = list(labels)
    issue = jira.create_issue(fields=fields)
    click.echo(issue.key)


def issue_update_fn(
    issue_key,
    summary=None,
    description=None,
    assignee=None,
    labels_add=None,
    labels_remove=None,
    issue_type=None,
):
    """Update an existing issue"""
    jira = get_jira_client()

    # Type changes use Bulk Move API (separate async operation)
    if issue_type:
        move_issue_type(jira, issue_key, issue_type)
        click.echo(f"Changed {issue_key} type to {issue_type}", err=True)
        # If only type change requested, we're done
        if not any([summary, description, assignee, labels_add, labels_remove]):
            return

    issue = jira.issue(issue_key)

    fields = {}
    update = {}

    if summary:
        fields["summary"] = summary
    if description:
        fields["description"] = description
    if assignee:
        fields["assignee"] = {"name": assignee}

    if labels_add or labels_remove:
        label_ops = []
        if labels_add:
            for label in labels_add:
                label_ops.append({"add": label})
        if labels_remove:
            for label in labels_remove:
                label_ops.append({"remove": label})
        update["labels"] = label_ops

    if not fields and not update:
        raise click.ClickException("No fields to update")

    if update:
        issue.update(fields=fields, update=update)
    else:
        issue.update(fields=fields)

    click.echo(f"Updated {issue_key}", err=True)


def status_get_fn(issue_key):
    """Get issue status"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)
    click.echo(issue.fields.status.name)


def issue_assign_fn(issue_key, user):
    """Assign or unassign an issue"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)

    if user.lower() == "x":
        issue.update(assignee=None)
        click.echo(f"Unassigned {issue_key}", err=True)
    else:
        issue.update(assignee={"name": user})
        click.echo(f"Assigned {issue_key} to {user}", err=True)


def issue_view_fn(issue_key):
    """View issue details"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)
    fields = issue.fields

    click.echo(f"Issue:       {issue.key}")
    click.echo(f"Summary:     {fields.summary}")
    click.echo(f"Status:      {fields.status.name}")
    click.echo(f"Type:        {fields.issuetype.name}")
    click.echo(f"Priority:    {fields.priority.name if fields.priority else 'None'}")

    assignee = fields.assignee.displayName if fields.assignee else "Unassigned"
    reporter = fields.reporter.displayName if fields.reporter else "Unknown"
    click.echo(f"Assignee:    {assignee}")
    click.echo(f"Reporter:    {reporter}")

    if hasattr(fields, "labels") and fields.labels:
        click.echo(f"Labels:      {', '.join(fields.labels)}")

    if hasattr(fields, "components") and fields.components:
        components = [c.name for c in fields.components]
        click.echo(f"Components:  {', '.join(components)}")

    click.echo(f"Created:     {fields.created}")
    click.echo(f"Updated:     {fields.updated}")
    if fields.resolutiondate:
        click.echo(f"Resolved:    {fields.resolutiondate}")

    if hasattr(fields, "parent") and fields.parent:
        click.echo(f"Parent:      {fields.parent.key}")

    click.echo()
    click.echo("-" * 60)
    click.echo("Description:")
    click.echo()
    if fields.description:
        click.echo(fields.description)
    else:
        click.echo("  (No description)")

    if hasattr(fields, "issuelinks") and fields.issuelinks:
        click.echo()
        click.echo("-" * 60)
        click.echo("Linked Issues:")
        click.echo()
        for link in fields.issuelinks:
            if hasattr(link, "outwardIssue"):
                click.echo(
                    f"{link.type.outward} {link.outwardIssue.key}: {link.outwardIssue.fields.summary}"
                )
            if hasattr(link, "inwardIssue"):
                click.echo(
                    f"{link.type.inward} {link.inwardIssue.key}: {link.inwardIssue.fields.summary}"
                )

    comments = jira.comments(issue)
    if comments:
        top_comment = comments[-1]
        click.echo()
        click.echo("-" * 60)
        click.echo(f"Latest Comment ({len(comments)} total):")
        click.echo()
        click.echo(f"Author:  {top_comment.author.displayName}")
        click.echo(f"Created: {top_comment.created}")
        click.echo()
        click.echo(top_comment.body)


def issue_fields_fn(filter_pattern=None):
    """List fields that may be required for transitions"""
    jira = get_jira_client()

    # Get all field definitions
    url = f"{jira._options['server']}/rest/api/2/field"
    response = jira._session.get(url)
    if response.status_code != 200:
        raise click.ClickException(f"Failed to get fields: {response.text}")

    all_fields = response.json()

    # Keywords that suggest transition-related fields
    transition_keywords = [
        "resolution", "steps", "action", "taken", "done", "closing",
        "reason", "complete", "finish", "resolve"
    ]

    if filter_pattern:
        # User-provided filter
        keywords = [filter_pattern.lower()]
    else:
        keywords = transition_keywords

    # Filter to custom fields matching keywords
    matching = []
    for f in all_fields:
        name = f.get("name", "").lower()
        if f.get("custom") and any(kw in name for kw in keywords):
            matching.append(f)

    if not matching:
        click.echo("No matching fields found")
        return

    click.echo(f"Fields matching transition-related keywords:")
    click.echo()
    for f in sorted(matching, key=lambda x: x.get("name", "")):
        fid = f.get("id")
        name = f.get("name")
        schema = f.get("schema", {})
        ftype = schema.get("type", "unknown")
        click.echo(f"  {fid}: {name} [{ftype}]")


def issue_link_fn(inward_key, outward_key, link_type):
    """Link two issues"""
    jira = get_jira_client()
    jira.create_issue_link(
        type=link_type, inwardIssue=inward_key, outwardIssue=outward_key
    )
    click.echo(f"Linked {inward_key} -> {outward_key} ({link_type})", err=True)


def issue_unlink_fn(key1, key2):
    """Remove link between two issues"""
    jira = get_jira_client()
    issue = jira.issue(key1)

    for link in issue.fields.issuelinks:
        linked_key = None
        if hasattr(link, "outwardIssue"):
            linked_key = link.outwardIssue.key
        elif hasattr(link, "inwardIssue"):
            linked_key = link.inwardIssue.key

        if linked_key == key2:
            jira.delete_issue_link(link.id)
            click.echo(f"Unlinked {key1} <-> {key2}", err=True)
            return

    raise click.ClickException(f"No link found between {key1} and {key2}")


def link_types_list_fn():
    """List available link types"""
    jira = get_jira_client()
    for lt in jira.issue_link_types():
        click.echo(f"{lt.name}")
        click.echo(f"  Inward:  {lt.inward}")
        click.echo(f"  Outward: {lt.outward}")
        click.echo()


def issue_types_list_fn(project=None, show_ids=False):
    """List available issue types"""
    jira = get_jira_client()

    if project:
        proj = jira.project(project)
        issue_types = proj.issueTypes
    else:
        issue_types = jira.issue_types()

    for it in issue_types:
        subtask = " (subtask)" if it.subtask else ""
        if show_ids:
            click.echo(f"{it.id}\t{it.name}{subtask}")
        else:
            click.echo(f"{it.name}{subtask}")


def issue_list_fn(
    project=None,
    parent=None,
    issue_type=None,
    status=None,
    assignee=None,
    reporter=None,
    priority=None,
    labels=None,
    jql=None,
    order_by="created",
    reverse=False,
    limit=50,
):
    """List issues with flexible JQL-based filtering"""
    jira = get_jira_client()

    jql_parts = []

    if jql:
        jql_parts.append(f"({jql})")

    if project:
        jql_parts.append(f'project = "{project}"')

    if parent:
        jql_parts.append(f"parent = {parent}")

    if issue_type:
        jql_parts.append(f'issuetype = "{issue_type}"')

    if status:
        if status.startswith("~"):
            jql_parts.append(f'status != "{status[1:]}"')
        else:
            jql_parts.append(f'status = "{status}"')

    if assignee:
        if assignee.lower() == "unassigned":
            jql_parts.append("assignee IS EMPTY")
        elif assignee.lower() == "me":
            email = os.getenv("JIRA_EMAIL")
            jql_parts.append(f'assignee = "{email}"')
        else:
            jql_parts.append(f'assignee = "{assignee}"')

    if reporter:
        if reporter.lower() == "me":
            email = os.getenv("JIRA_EMAIL")
            jql_parts.append(f'reporter = "{email}"')
        else:
            jql_parts.append(f'reporter = "{reporter}"')

    if priority:
        jql_parts.append(f'priority = "{priority}"')

    if labels:
        for label in labels:
            if label.startswith("~"):
                jql_parts.append(f'labels != "{label[1:]}"')
            else:
                jql_parts.append(f'labels = "{label}"')

    if not jql_parts:
        raise click.ClickException("At least one filter is required (--project, --parent, --jql, etc.)")

    order_dir = "ASC" if reverse else "DESC"
    jql_query = " AND ".join(jql_parts) + f" ORDER BY {order_by} {order_dir}"

    issues = jira.search_issues(jql_query, maxResults=limit)

    if not issues:
        click.echo("No issues found", err=True)
        return

    click.echo(f"{'KEY':<15} {'TYPE':<12} {'STATUS':<15} {'ASSIGNEE':<20} {'SUMMARY'}")
    click.echo("-" * 100)

    for issue in issues:
        key = issue.key
        itype = issue.fields.issuetype.name[:10]
        status_name = issue.fields.status.name[:13]
        assignee_name = issue.fields.assignee.displayName[:18] if issue.fields.assignee else "Unassigned"
        summary = issue.fields.summary
        if len(summary) > 35:
            summary = summary[:32] + "..."
        click.echo(f"{key:<15} {itype:<12} {status_name:<15} {assignee_name:<20} {summary}")


@click.group("issue")
def issue_group():
    """Manage issues"""
    pass


# Add subgroups
issue_group.add_command(comment_group)
issue_group.add_command(transition_group)


@issue_group.command("create")
@click.argument("project")
@click.argument("summary")
@click.option("--type", "issue_type", default="Task", help="Issue type (default: Task)")
@click.option("-d", "--description", help="Issue description")
@click.option("-p", "--parent", help="Parent issue key for sub-tasks")
@click.option("-a", "--assignee", help="Assignee email/name")
@click.option("-l", "--label", multiple=True, help="Add label (can be repeated)")
def issue_create_cmd(project, summary, issue_type, description, parent, assignee, label):
    """Create a new issue"""
    labels = list(label) if label else None
    issue_create_fn(project, summary, issue_type, description, parent, assignee, labels)


@issue_group.command("update")
@click.argument("issue_key")
@click.option("-s", "--summary", help="New issue summary/title")
@click.option("-d", "--description", help="New issue description")
@click.option("-a", "--assignee", help="New assignee (email/name)")
@click.option("-l", "--label", multiple=True, help="Add/remove label (prefix with - to remove)")
@click.option("-t", "--type", "issue_type", help="Change issue type (e.g., Task, Story, Bug)")
def issue_update_cmd(issue_key, summary, description, assignee, label, issue_type):
    """Update an existing issue"""
    labels_add, labels_remove = parse_labels(list(label)) if label else (None, None)
    issue_update_fn(issue_key, summary, description, assignee, labels_add, labels_remove, issue_type)


@issue_group.command("view")
@click.argument("issue_key")
def issue_view_cmd(issue_key):
    """View issue details"""
    issue_view_fn(issue_key)


@issue_group.command("status")
@click.argument("issue_key")
def issue_status_cmd(issue_key):
    """Get issue status"""
    status_get_fn(issue_key)


@issue_group.command("fields")
@click.option("-f", "--filter", "filter_pattern", help="Filter fields by name pattern")
def issue_fields_cmd(filter_pattern):
    """List custom fields that may be required for transitions"""
    issue_fields_fn(filter_pattern)


@issue_group.command("assign")
@click.argument("issue_key")
@click.argument("user")
def issue_assign_cmd(issue_key, user):
    """Assign/unassign issue (use 'x' to unassign)"""
    issue_assign_fn(issue_key, user)


@issue_group.command("link")
@click.argument("inward_key")
@click.argument("outward_key")
@click.argument("link_type")
def issue_link_cmd(inward_key, outward_key, link_type):
    """Link two issues"""
    issue_link_fn(inward_key, outward_key, link_type)


@issue_group.command("unlink")
@click.argument("key1")
@click.argument("key2")
def issue_unlink_cmd(key1, key2):
    """Remove link between issues"""
    issue_unlink_fn(key1, key2)


@issue_group.command("link-types")
def issue_link_types_cmd():
    """List available link types"""
    link_types_list_fn()


@issue_group.command("types")
@click.option("-p", "--project", help="Show types for specific project")
@click.option("--ids", is_flag=True, help="Show issue type IDs")
def issue_types_cmd(project, ids):
    """List available issue types"""
    issue_types_list_fn(project, ids)


@issue_group.command("list")
@click.option("-p", "--project", help="Filter by project key")
@click.option("-P", "--parent", help="Filter by parent issue key (list children)")
@click.option("-t", "--type", "issue_type", help="Filter by issue type")
@click.option("-s", "--status", help="Filter by status (prefix ~ to exclude)")
@click.option("-a", "--assignee", help="Filter by assignee (use 'me' or 'unassigned')")
@click.option("-r", "--reporter", help="Filter by reporter (use 'me')")
@click.option("-y", "--priority", help="Filter by priority")
@click.option("-l", "--label", multiple=True, help="Filter by label (prefix ~ to exclude)")
@click.option("-q", "--jql", help="Raw JQL query (combined with other filters)")
@click.option("--order-by", default="created", help="Sort field (default: created)")
@click.option("--reverse", is_flag=True, help="Reverse sort order (ASC instead of DESC)")
@click.option("-n", "--limit", type=int, default=50, help="Max results (default: 50)")
def issue_list_cmd(project, parent, issue_type, status, assignee, reporter, priority, label, jql, order_by, reverse, limit):
    """List issues with flexible filtering

    Examples:

      # List children of an issue
      jira-custom issue list -P PROJ-28797

      # List all tasks in a project
      jira-custom issue list -p PROJ -t Task

      # List my open issues
      jira-custom issue list -p PROJ -a me -s "~Done"

      # Raw JQL query
      jira-custom issue list -q "sprint in openSprints()"
    """
    labels = list(label) if label else None
    issue_list_fn(project, parent, issue_type, status, assignee, reporter, priority, labels, jql, order_by, reverse, limit)
