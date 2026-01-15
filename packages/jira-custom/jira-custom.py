#!/usr/bin/env python3

from jira import JIRA
import sys
import os
import webbrowser
import click

# Fix program name in usage output when run via Nix store path
sys.argv[0] = "jira-custom"


def get_jira_client():
    """Get authenticated JIRA client"""
    server = os.getenv("JIRA_SERVER")
    email = os.getenv("JIRA_EMAIL")
    token = os.getenv("JIRA_API_TOKEN")

    if not all([server, email, token]):
        raise click.ClickException(
            "Set JIRA_SERVER, JIRA_EMAIL, and JIRA_API_TOKEN in environment"
        )

    return JIRA(server=server, basic_auth=(email, token))


def parse_labels(labels):
    """Parse label arguments, separating adds from removes"""
    if not labels:
        return None, None

    add = []
    remove = []

    for label in labels:
        if label.startswith("-"):
            remove.append(label[1:])
        else:
            add.append(label)

    return add or None, remove or None


def parse_fields(field_args):
    """Parse field arguments (KEY=VALUE format)"""
    if not field_args:
        return None

    fields = {}
    for f in field_args:
        if "=" not in f:
            raise click.ClickException(f"Invalid field format '{f}'. Use KEY=VALUE")
        key, value = f.split("=", 1)
        fields[key] = value
    return fields


# =============================================================================
# Business Logic Functions
# =============================================================================


def search_filters_fn(query=None):
    """Search for Jira filters"""
    jira = get_jira_client()
    filters = jira.favourite_filters()

    if query:
        filters = [f for f in filters if query.lower() in f.name.lower()]

    for f in filters:
        click.echo(f"{f.id}: {f.name}")
        click.echo(f"  Owner: {f.owner.displayName}")
        click.echo(f"  JQL: {f.jql}")
        click.echo()


def comment_list_fn(issue_key, last=None, order="desc"):
    """List comments on an issue"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)
    comments = jira.comments(issue)

    if not comments:
        click.echo(f"No comments on {issue_key}")
        return

    if order == "desc":
        comments = list(reversed(comments))

    if last is not None:
        comments = comments[:last]

    for comment in comments:
        click.echo(f"ID: {comment.id}")
        click.echo(f"Author: {comment.author.displayName}")
        click.echo(f"Created: {comment.created}")
        click.echo(f"Body:\n{comment.body}")
        click.echo("-" * 80)


def comment_add_fn(issue_key, body):
    """Add a comment to an issue"""
    jira = get_jira_client()
    comment = jira.add_comment(issue_key, body)
    click.echo(f"{comment.id}")
    return comment.id


def comment_update_fn(issue_key, comment_id, body):
    """Update an existing comment"""
    jira = get_jira_client()
    comment = jira.comment(issue_key, comment_id)
    comment.update(body=body)
    click.echo(f"Comment {comment_id} updated successfully", err=True)


def comment_delete_fn(issue_key, comment_id):
    """Delete a comment"""
    jira = get_jira_client()
    comment = jira.comment(issue_key, comment_id)
    comment.delete()
    click.echo(f"Comment {comment_id} deleted successfully", err=True)


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
):
    """Update an existing issue"""
    jira = get_jira_client()
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


def transition_list_fn(issue_key):
    """List available transitions for an issue"""
    jira = get_jira_client()
    transitions = jira.transitions(issue_key)
    for t in transitions:
        click.echo(f"{t['id']}: {t['name']}")


def transition_fields_fn(issue_key, transition_name):
    """List fields available for a transition"""
    jira = get_jira_client()
    transitions = jira.transitions(issue_key, expand="transitions.fields")

    target = None
    for t in transitions:
        if t["name"].lower() == transition_name.lower() or t["id"] == transition_name:
            target = t
            break

    if not target:
        click.echo(f"Transition '{transition_name}' not found", err=True)
        click.echo("Available transitions:", err=True)
        for t in transitions:
            click.echo(f"  {t['id']}: {t['name']}", err=True)
        sys.exit(1)

    click.echo(f"Transition: {target['name']} (id: {target['id']})")
    click.echo()

    fields = target.get("fields", {})
    if not fields:
        click.echo("No fields available for this transition")
        return

    click.echo("Fields:")
    for field_id, field_info in fields.items():
        required = field_info.get("required", False)
        name = field_info.get("name", field_id)
        field_type = field_info.get("schema", {}).get("type", "unknown")
        req_marker = " (required)" if required else ""
        click.echo(f"  {field_id}: {name} [{field_type}]{req_marker}")


def transition_issue_fn(issue_key, transition_name, comment=None, fields=None, open_web=False):
    """Transition an issue to a new status"""
    jira = get_jira_client()
    jira.transition_issue(issue_key, transition_name, fields=fields)
    issue = jira.issue(issue_key)
    click.echo(f"Transitioned to: {issue.fields.status.name}", err=True)
    if comment:
        jira.add_comment(issue_key, comment)
        click.echo("Comment added", err=True)
    if open_web:
        server = os.getenv("JIRA_SERVER")
        url = f"{server}/browse/{issue_key}"
        webbrowser.open(url)
        click.echo(f"Opened {url}", err=True)


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
        jql_parts.append('status NOT IN ("Done", "Closed", "removed", "Not a bug")')

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


def open_issue_fn(issue_key=None):
    """Open issue or project in browser"""
    server = os.getenv("JIRA_SERVER")

    if issue_key:
        url = f"{server}/browse/{issue_key}"
    else:
        url = server

    webbrowser.open(url)
    click.echo(f"Opened {url}", err=True)


def show_me_fn():
    """Show current user info"""
    jira = get_jira_client()
    user = jira.myself()

    click.echo(f"Name:     {user.displayName}")
    click.echo(f"Email:    {user.emailAddress}")
    click.echo(f"Account:  {user.accountId if hasattr(user, 'accountId') else user.name}")
    click.echo(f"Active:   {user.active}")
    click.echo(f"Timezone: {user.timeZone if hasattr(user, 'timeZone') else 'N/A'}")


def show_serverinfo_fn():
    """Show Jira server information"""
    jira = get_jira_client()
    info = jira.server_info()

    click.echo(f"Server:      {info.get('baseUrl', 'N/A')}")
    click.echo(f"Version:     {info.get('version', 'N/A')}")
    click.echo(f"Build:       {info.get('buildNumber', 'N/A')}")
    click.echo(f"Deployment:  {info.get('deploymentType', 'N/A')}")
    click.echo(f"Server Time: {info.get('serverTime', 'N/A')}")


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


def project_list_fn():
    """List projects"""
    jira = get_jira_client()

    projects = jira.projects()

    if not projects:
        click.echo("No projects found", err=True)
        return

    click.echo(f"{'KEY':<15} {'NAME'}")
    click.echo("-" * 60)

    for project in projects:
        key = project.key
        name = project.name
        click.echo(f"{key:<15} {name}")


def release_list_fn(project):
    """List releases/versions for a project"""
    jira = get_jira_client()

    versions = jira.project_versions(project)

    if not versions:
        click.echo(f"No releases found for {project}", err=True)
        return

    click.echo(f"{'ID':<10} {'NAME':<30} {'RELEASED':<10} {'RELEASE DATE'}")
    click.echo("-" * 70)

    for version in versions:
        vid = version.id
        name = version.name[:28] + ".." if len(version.name) > 30 else version.name
        released = "Yes" if version.released else "No"
        release_date = getattr(version, "releaseDate", "N/A") or "N/A"
        click.echo(f"{vid:<10} {name:<30} {released:<10} {release_date}")


# =============================================================================
# CLI Commands
# =============================================================================


@click.group(context_settings={"help_option_names": ["-h", "--help"]})
def cli():
    """Custom JIRA operations"""
    pass


# -----------------------------------------------------------------------------
# Top-level commands
# -----------------------------------------------------------------------------


@cli.command("filter")
@click.argument("query", required=False)
def filter_cmd(query):
    """Search for JIRA filters"""
    search_filters_fn(query)


@cli.command("my")
@click.argument("scope", type=click.Choice(["sprint", "project", "all"]), default="sprint")
@click.option("-p", "--project", help="Project key (required for 'project' scope)")
@click.option("-a", "--all-statuses", is_flag=True, help="Include done/closed issues")
@click.option("--priority", help="Filter by priority (e.g., High, Medium)")
@click.option("--status", help="Filter by status (e.g., 'In Progress')")
@click.option("-l", "--limit", type=int, default=50, help="Max results (default: 50)")
def my_cmd(scope, project, all_statuses, priority, status, limit):
    """List my issues"""
    my_issues_fn(scope, project, not all_statuses, priority, status, limit)


@cli.command("open")
@click.argument("issue_key", required=False)
def open_cmd(issue_key):
    """Open issue in browser"""
    open_issue_fn(issue_key)


@cli.command("me")
def me_cmd():
    """Show current user"""
    show_me_fn()


@cli.command("serverinfo")
def serverinfo_cmd():
    """Show server info"""
    show_serverinfo_fn()


# -----------------------------------------------------------------------------
# Sprint commands
# -----------------------------------------------------------------------------


@cli.group("sprint")
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


# -----------------------------------------------------------------------------
# Epic commands
# -----------------------------------------------------------------------------


@cli.group("epic")
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
@click.argument("epic_key")
@click.argument("issue_keys", nargs=-1, required=True)
def epic_add_cmd(epic_key, issue_keys):
    """Add issues to epic"""
    epic_add_fn(epic_key, issue_keys)


@epic_group.command("remove")
@click.argument("issue_keys", nargs=-1, required=True)
def epic_remove_cmd(issue_keys):
    """Remove issues from epic"""
    epic_remove_fn(issue_keys)


# -----------------------------------------------------------------------------
# Board commands
# -----------------------------------------------------------------------------


@cli.group("board")
def board_group():
    """Manage boards"""
    pass


@board_group.command("list")
@click.option("-p", "--project", help="Filter by project")
@click.option("-t", "--type", "board_type", type=click.Choice(["scrum", "kanban"]), help="Board type")
def board_list_cmd(project, board_type):
    """List boards"""
    board_list_fn(project, board_type)


# -----------------------------------------------------------------------------
# Project commands
# -----------------------------------------------------------------------------


@cli.group("project")
def project_group():
    """Manage projects"""
    pass


@project_group.command("list")
def project_list_cmd():
    """List projects"""
    project_list_fn()


# -----------------------------------------------------------------------------
# Release commands
# -----------------------------------------------------------------------------


@cli.group("release")
def release_group():
    """Manage releases"""
    pass


@release_group.command("list")
@click.argument("project")
def release_list_cmd(project):
    """List releases"""
    release_list_fn(project)


# -----------------------------------------------------------------------------
# Issue commands
# -----------------------------------------------------------------------------


@cli.group("issue")
def issue_group():
    """Manage issues"""
    pass


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
def issue_update_cmd(issue_key, summary, description, assignee, label):
    """Update an existing issue"""
    labels_add, labels_remove = parse_labels(list(label)) if label else (None, None)
    issue_update_fn(issue_key, summary, description, assignee, labels_add, labels_remove)


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


# -----------------------------------------------------------------------------
# Issue transition subgroup
# -----------------------------------------------------------------------------


@issue_group.group("transition")
def transition_group():
    """Manage issue transitions"""
    pass


@transition_group.command("list")
@click.argument("issue_key")
def transition_list_cmd(issue_key):
    """List available transitions"""
    transition_list_fn(issue_key)


@transition_group.command("fields")
@click.argument("issue_key")
@click.argument("transition_name")
def transition_fields_cmd(issue_key, transition_name):
    """List fields for a transition"""
    transition_fields_fn(issue_key, transition_name)


@transition_group.command("to")
@click.argument("issue_key")
@click.argument("transition_name")
@click.option("-c", "--comment", help="Add a comment after transitioning")
@click.option("-f", "--field", multiple=True, help="Set field during transition (KEY=VALUE)")
@click.option("-w", "--web", is_flag=True, help="Open issue in browser after transition")
def transition_to_cmd(issue_key, transition_name, comment, field, web):
    """Transition issue to a new status"""
    fields = parse_fields(field)
    transition_issue_fn(issue_key, transition_name, comment, fields, web)


# -----------------------------------------------------------------------------
# Issue comment subgroup
# -----------------------------------------------------------------------------


@issue_group.group("comment")
def comment_group():
    """Manage issue comments"""
    pass


@comment_group.command("list")
@click.argument("issue_key")
@click.option("--last", type=int, help="Show only last N comments")
@click.option("--order", type=click.Choice(["asc", "desc"]), default="desc", help="Sort order")
def comment_list_cmd(issue_key, last, order):
    """List comments on an issue"""
    comment_list_fn(issue_key, last, order)


@comment_group.command("add")
@click.argument("issue_key")
@click.argument("body")
def comment_add_cmd(issue_key, body):
    """Add a comment to an issue"""
    comment_add_fn(issue_key, body)


@comment_group.command("update")
@click.argument("issue_key")
@click.argument("comment_id")
@click.argument("body")
def comment_update_cmd(issue_key, comment_id, body):
    """Update a comment"""
    comment_update_fn(issue_key, comment_id, body)


@comment_group.command("delete")
@click.argument("issue_key")
@click.argument("comment_id")
def comment_delete_cmd(issue_key, comment_id):
    """Delete a comment"""
    comment_delete_fn(issue_key, comment_id)


if __name__ == "__main__":
    cli()
