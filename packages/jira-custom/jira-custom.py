#!/usr/bin/env python3

from jira import JIRA
import sys
import os
import webbrowser
import click
from rich.console import Console
from rich.table import Table
from rich.markup import escape
from rich import box

# Fix program name in usage output when run via Nix store path
sys.argv[0] = "jira-custom"

# Status categories for filtering and styling
# Used in JQL queries and get_status_style()
STATUS_DONE = frozenset({"done", "closed", "resolved", "declined"})
STATUS_DONE_JQL = frozenset({"Done", "Closed", "Resolved", "Declined", "removed", "Not a bug"})
STATUS_IN_PROGRESS = frozenset({"in progress", "in review", "review"})
STATUS_BLOCKED = frozenset({"blocked", "impediment"})
STATUS_TODO = frozenset({"to do", "open", "backlog", "unresolved"})

# Default terminal width fallback for CI/pipes where console.width is None
DEFAULT_TERMINAL_WIDTH = 120


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


def get_issue_type_id_for_project(jira, project_key, type_name):
    """Get issue type ID by name using createmeta endpoint"""
    url = f"{jira._options['server']}/rest/api/3/issue/createmeta/{project_key}/issuetypes"
    response = jira._session.get(url)

    if response.status_code != 200:
        raise click.ClickException(f"Failed to get issue types: {response.text}")

    data = response.json()
    for it in data.get("issueTypes", data.get("values", [])):
        if it.get("name", "").lower() == type_name.lower():
            return it.get("id")

    available = [it.get("name") for it in data.get("issueTypes", data.get("values", []))]
    raise click.ClickException(
        f"Issue type '{type_name}' not found in project {project_key}. "
        f"Available: {', '.join(available)}"
    )


def move_issue_type(jira, issue_key, type_name):
    """Change issue type using Bulk Move API (async operation)"""
    import time

    issue = jira.issue(issue_key)
    project_key = issue.fields.project.key
    type_id = get_issue_type_id_for_project(jira, project_key, type_name)

    # Build composite mapping key: "PROJECT_KEY,ISSUE_TYPE_ID"
    mapping_key = f"{project_key},{type_id}"

    payload = {
        "sendBulkNotification": True,  # Must be True to avoid permission error
        "targetToSourcesMapping": {
            mapping_key: {
                "issueIdsOrKeys": [issue_key],
                "inferClassificationDefaults": True,
                "inferFieldDefaults": True,
                "inferStatusDefaults": True,
                "inferSubtaskTypeDefault": True,
            }
        },
    }

    # Submit bulk move request
    url = f"{jira._options['server']}/rest/api/3/bulk/issues/move"
    response = jira._session.post(url, json=payload)

    if response.status_code not in (200, 201, 202):
        error_msg = response.text
        try:
            error_data = response.json()
            if "errorMessages" in error_data:
                error_msg = "; ".join(error_data["errorMessages"])
            elif "errors" in error_data:
                error_msg = "; ".join(f"{k}: {v}" for k, v in error_data["errors"].items())
        except Exception:
            pass
        raise click.ClickException(f"Move failed ({response.status_code}): {error_msg}")

    result = response.json()
    task_id = result.get("taskId")

    if not task_id:
        raise click.ClickException(f"No taskId in response: {result}")

    # Poll for completion
    queue_url = f"{jira._options['server']}/rest/api/3/bulk/queue/{task_id}"
    timeout = 120
    start_time = time.time()

    while time.time() - start_time < timeout:
        status_response = jira._session.get(queue_url)
        if status_response.status_code != 200:
            raise click.ClickException(f"Failed to check task status: {status_response.text}")

        status_data = status_response.json()
        status = status_data.get("status")

        if status == "COMPLETE":
            return status_data
        elif status == "FAILED":
            raise click.ClickException(f"Move failed: {status_data}")

        time.sleep(2)

    raise click.ClickException(f"Move timed out after {timeout}s (task: {task_id})")


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


def get_status_style(status_name):
    """Get rich style for status name.

    Colors chosen for color blindness accessibility:
    - Avoids red-green distinction (problematic for 8% of males)
    - Uses brightness/saturation differences alongside hue
    """
    status_lower = status_name.lower()
    if status_lower in STATUS_DONE:
        return "[dim strike]"  # Dimmed + strikethrough indicates completed
    elif status_lower in STATUS_IN_PROGRESS:
        return "[bold bright_cyan]"  # bright_cyan distinct from Reporter's blue
    elif status_lower in STATUS_BLOCKED:
        return "[bold bright_magenta]"  # Magenta instead of red for color blindness
    elif status_lower in STATUS_TODO:
        return "[yellow]"
    return "[white]"


def get_priority_style(priority_name):
    """Get rich style for priority.

    Uses style-based distinction (bold, underline, reverse) rather than
    color-only to be accessible for color blindness.
    No color repeats with cell attribute values.
    """
    if not priority_name:
        return "[dim]", "None"
    priority_lower = priority_name.lower()
    if priority_lower in ("highest", "blocker"):
        return "[bold reverse]", priority_name  # Inverted - maximum visibility
    elif priority_lower in ("high", "critical"):
        return "[bold underline]", priority_name
    elif priority_lower == "medium":
        return "[bright_black]", priority_name  # Gray - neutral
    elif priority_lower in ("low", "lowest", "minor", "trivial"):
        return "[dim italic]", priority_name
    return "[white]", priority_name


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


def truncate_text(text, max_len):
    """Truncate text to max_len, adding ellipsis if needed"""
    if len(text) <= max_len:
        return text
    if max_len <= 3:
        return text[:max_len]
    return text[:max_len - 3] + "..."


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


def format_issue_cell_fn(issue, col_width):
    """Format a single issue as a Rich-formatted cell string"""
    key = escape(issue.key)
    summary = escape(truncate_text(issue.fields.summary, col_width - 2))

    reporter = issue.fields.reporter.displayName if issue.fields.reporter else "Unknown"
    reporter = escape(truncate_text(reporter, col_width - 2))

    updated = issue.fields.updated[:16].replace("T", " ") if issue.fields.updated else ""

    resolution = issue.fields.resolution.name if issue.fields.resolution else "Unresolved"
    resolution = escape(resolution)

    priority = issue.fields.priority.name if issue.fields.priority else "None"
    prio_short = escape(priority[:3])
    prio_style, _ = get_priority_style(priority)

    assignee = issue.fields.assignee.displayName if issue.fields.assignee else "Unassigned"
    assignee = escape(truncate_text(assignee, col_width - 2))

    # Colors chosen for color blindness accessibility (high contrast, distinct hues)
    # Reporter uses [blue] to avoid overlap with In Progress status [bold bright_cyan]
    return (
        f"[dim]Summary:   [/] [bold yellow]{summary}[/]\n"
        f"[dim]Reporter:  [/] [blue]{reporter}[/]\n"
        f"[dim]Date:      [/] [bright_white]{updated}[/]\n"
        f"[dim]Resolution:[/] [magenta]{resolution}[/]\n"
        f"[dim]Key:       [/] [bold bright_blue]{key}[/]\n"
        f"[dim]Priority:  [/] {prio_style}{prio_short}[/]\n"
        f"[dim]Assignee:  [/] [bold bright_green]{assignee}[/]"
    )


def render_board_table_fn(console, issues_by_status, all_columns):
    """Render issues as a kanban board table"""
    # Calculate dynamic column width based on terminal size
    try:
        terminal_width = int(os.getenv("COLUMNS", 0)) or console.width or DEFAULT_TERMINAL_WIDTH
    except ValueError:
        terminal_width = console.width or DEFAULT_TERMINAL_WIDTH

    num_columns = len(all_columns)
    available_width = terminal_width - (num_columns + 1) * 3
    col_width = max(20, available_width // num_columns)

    table = Table(
        show_header=True,
        header_style="bold cyan",
        box=box.ROUNDED,
        padding=(0, 1),
        width=terminal_width,
    )

    for col_status in all_columns:
        count = len(issues_by_status.get(col_status, []))
        style = get_status_style(col_status)
        table.add_column(f"{style}{col_status}[/] ({count})", ratio=1, no_wrap=True, overflow="ellipsis")

    max_rows = max(len(issues_by_status.get(s, [])) for s in all_columns) if all_columns else 0

    for row_idx in range(max_rows):
        row_data = []
        for col_status in all_columns:
            col_issues = issues_by_status.get(col_status, [])
            if row_idx < len(col_issues):
                row_data.append(format_issue_cell_fn(col_issues[row_idx], col_width))
            else:
                row_data.append("")
        table.add_row(*row_data)
        if row_idx < max_rows - 1:
            table.add_section()

    console.print(table)

    # Summary stats
    total = sum(len(issues_by_status[s]) for s in issues_by_status)
    stats_parts = [f"[bold]{total}[/bold] issues"]
    for s, issues in sorted(issues_by_status.items(), key=lambda x: -len(x[1])):
        style = get_status_style(s)
        stats_parts.append(f"{style}{len(issues)} {s}[/]")
    console.print(" | ".join(stats_parts))


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


@board_group.command("view")
@click.option("-b", "--id", "board_id", help="Board ID (or set JIRA_BOARD_ID)")
@click.option("-n", "--name", "board_name", help="Board name (partial match supported)")
@click.option("-a", "--all", "show_done", is_flag=True, help="Include Done/Resolved issues")
@click.option("--all-in-progress", "all_in_progress", is_flag=True, help="Show all In Progress issues (not just mine)")
@click.option("-l", "--limit", type=int, default=100, help="Max results (default: 100)")
def board_view_cmd(board_id, board_name, show_done, all_in_progress, limit):
    """View board issues in a table"""
    board_view_fn(board_id, board_name, show_done, limit, my_in_progress=not all_in_progress)


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
