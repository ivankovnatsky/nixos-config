#!/usr/bin/env python3

from jira import JIRA
import sys
import os
import argparse


def get_jira_client():
    """Get authenticated JIRA client"""
    server = os.getenv("JIRA_SERVER")
    email = os.getenv("JIRA_EMAIL")
    token = os.getenv("JIRA_API_TOKEN")

    if not all([server, email, token]):
        print(
            "Error: Set JIRA_SERVER, JIRA_EMAIL, and JIRA_API_TOKEN in environment",
            file=sys.stderr,
        )
        sys.exit(1)

    return JIRA(server=server, basic_auth=(email, token))


def search_filters(query=None):
    """Search for Jira filters"""
    jira = get_jira_client()

    # Get all filters accessible to the user
    filters = jira.favourite_filters()

    if query:
        # Filter by query
        filters = [f for f in filters if query.lower() in f.name.lower()]

    # Display filters
    for f in filters:
        print(f"{f.id}: {f.name}")
        print(f"  Owner: {f.owner.displayName}")
        print(f"  JQL: {f.jql}")
        print()


def comment_list(issue_key, last=None, order="desc"):
    """List comments on an issue"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)
    comments = jira.comments(issue)

    if not comments:
        print(f"No comments on {issue_key}")
        return

    # Sort by order (desc = newest first, asc = oldest first)
    if order == "desc":
        comments = list(reversed(comments))

    # Show last N comments if specified
    if last is not None:
        comments = comments[:last]

    for comment in comments:
        print(f"ID: {comment.id}")
        print(f"Author: {comment.author.displayName}")
        print(f"Created: {comment.created}")
        print(f"Body:\n{comment.body}")
        print("-" * 80)


def comment_add(issue_key, body):
    """Add a comment to an issue"""
    jira = get_jira_client()
    comment = jira.add_comment(issue_key, body)
    print(f"{comment.id}")  # Output only the comment ID for scripting
    return comment.id


def comment_update(issue_key, comment_id, body):
    """Update an existing comment"""
    try:
        jira = get_jira_client()
        comment = jira.comment(issue_key, comment_id)
        comment.update(body=body)
        print(f"Comment {comment_id} updated successfully", file=sys.stderr)
    except Exception as e:
        print(f"Error updating comment: {e}", file=sys.stderr)
        sys.exit(1)


def comment_delete(issue_key, comment_id):
    """Delete a comment"""
    jira = get_jira_client()
    comment = jira.comment(issue_key, comment_id)
    comment.delete()
    print(f"Comment {comment_id} deleted successfully", file=sys.stderr)


def issue_create(
    project, summary, issue_type="Task", description=None, parent=None, assignee=None
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
    issue = jira.create_issue(fields=fields)
    print(issue.key)


def issue_update(issue_key, summary=None, description=None, assignee=None):
    """Update an existing issue"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)
    fields = {}
    if summary:
        fields["summary"] = summary
    if description:
        fields["description"] = description
    if assignee:
        fields["assignee"] = {"name": assignee}
    if not fields:
        print("No fields to update", file=sys.stderr)
        sys.exit(1)
    issue.update(fields=fields)
    print(f"Updated {issue_key}", file=sys.stderr)


def status_get(issue_key):
    """Get issue status"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)
    print(issue.fields.status.name)


def issue_assign(issue_key, user):
    """Assign or unassign an issue"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)

    if user.lower() == "x":
        # Unassign
        issue.update(assignee=None)
        print(f"Unassigned {issue_key}", file=sys.stderr)
    else:
        # Assign - user can be email or accountId
        issue.update(assignee={"name": user})
        print(f"Assigned {issue_key} to {user}", file=sys.stderr)


def issue_view(issue_key):
    """View issue details"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)
    fields = issue.fields

    # Header
    print(f"Issue:       {issue.key}")
    print(f"Summary:     {fields.summary}")
    print(f"Status:      {fields.status.name}")
    print(f"Type:        {fields.issuetype.name}")
    print(f"Priority:    {fields.priority.name if fields.priority else 'None'}")

    # Assignee and Reporter
    assignee = fields.assignee.displayName if fields.assignee else "Unassigned"
    reporter = fields.reporter.displayName if fields.reporter else "Unknown"
    print(f"Assignee:    {assignee}")
    print(f"Reporter:    {reporter}")

    # Labels
    if hasattr(fields, "labels") and fields.labels:
        print(f"Labels:      {', '.join(fields.labels)}")

    # Components
    if hasattr(fields, "components") and fields.components:
        components = [c.name for c in fields.components]
        print(f"Components:  {', '.join(components)}")

    # Dates
    print(f"Created:     {fields.created}")
    print(f"Updated:     {fields.updated}")
    if fields.resolutiondate:
        print(f"Resolved:    {fields.resolutiondate}")

    # Parent (for sub-tasks)
    if hasattr(fields, "parent") and fields.parent:
        print(f"Parent:      {fields.parent.key}")

    # Description
    print()
    print("-" * 60)
    print("Description:")
    print()
    if fields.description:
        print(fields.description)
    else:
        print("  (No description)")

    # Linked issues
    if hasattr(fields, "issuelinks") and fields.issuelinks:
        print()
        print("-" * 60)
        print("Linked Issues:")
        print()
        for link in fields.issuelinks:
            if hasattr(link, "outwardIssue"):
                print(
                    f"{link.type.outward} {link.outwardIssue.key}: {link.outwardIssue.fields.summary}"
                )
            if hasattr(link, "inwardIssue"):
                print(
                    f"{link.type.inward} {link.inwardIssue.key}: {link.inwardIssue.fields.summary}"
                )

    # Top comment
    comments = jira.comments(issue)
    if comments:
        top_comment = comments[-1]  # Most recent comment
        print()
        print("-" * 60)
        print(f"Latest Comment ({len(comments)} total):")
        print()
        print(f"Author:  {top_comment.author.displayName}")
        print(f"Created: {top_comment.created}")
        print()
        print(top_comment.body)


def transition_list(issue_key):
    """List available transitions for an issue"""
    jira = get_jira_client()
    transitions = jira.transitions(issue_key)
    for t in transitions:
        print(f"{t['id']}: {t['name']}")


def transition_fields(issue_key, transition_name):
    """List fields available for a transition"""
    jira = get_jira_client()
    transitions = jira.transitions(issue_key, expand="transitions.fields")

    # Find the matching transition
    target = None
    for t in transitions:
        if t["name"].lower() == transition_name.lower() or t["id"] == transition_name:
            target = t
            break

    if not target:
        print(f"Transition '{transition_name}' not found", file=sys.stderr)
        print("Available transitions:", file=sys.stderr)
        for t in transitions:
            print(f"  {t['id']}: {t['name']}", file=sys.stderr)
        sys.exit(1)

    print(f"Transition: {target['name']} (id: {target['id']})")
    print()

    fields = target.get("fields", {})
    if not fields:
        print("No fields available for this transition")
        return

    print("Fields:")
    for field_id, field_info in fields.items():
        required = field_info.get("required", False)
        name = field_info.get("name", field_id)
        field_type = field_info.get("schema", {}).get("type", "unknown")
        req_marker = " (required)" if required else ""
        print(f"  {field_id}: {name} [{field_type}]{req_marker}")


def transition_issue(issue_key, transition_name, comment=None, fields=None):
    """Transition an issue to a new status"""
    jira = get_jira_client()
    jira.transition_issue(issue_key, transition_name, fields=fields)
    issue = jira.issue(issue_key)
    print(f"Transitioned to: {issue.fields.status.name}", file=sys.stderr)
    if comment:
        jira.add_comment(issue_key, comment)
        print("Comment added", file=sys.stderr)


def my_issues(
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

    # Build JQL query
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
        print("No issues found", file=sys.stderr)
        return

    # Print header
    print(f"{'KEY':<15} {'STATUS':<15} {'PRIORITY':<10} {'SUMMARY'}")
    print("-" * 80)

    for issue in issues:
        key = issue.key
        status_name = issue.fields.status.name
        priority_name = issue.fields.priority.name if issue.fields.priority else "None"
        summary = issue.fields.summary
        # Truncate summary if too long
        if len(summary) > 45:
            summary = summary[:42] + "..."
        print(f"{key:<15} {status_name:<15} {priority_name:<10} {summary}")


def main():
    parser = argparse.ArgumentParser(description="Custom JIRA operations")
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Filter command
    filter_parser = subparsers.add_parser("filter", help="Search for JIRA filters")
    filter_parser.add_argument("query", nargs="?", help="Filter name query")

    # My command - list issues assigned to current user
    my_parser = subparsers.add_parser("my", help="List my issues")
    my_parser.add_argument(
        "scope",
        nargs="?",
        choices=["sprint", "project", "all"],
        default="sprint",
        help="Scope: sprint (current sprint), project, or all (default: sprint)",
    )
    my_parser.add_argument(
        "-p", "--project", help="Project key (required for 'project' scope)"
    )
    my_parser.add_argument(
        "-a",
        "--all-statuses",
        action="store_true",
        help="Include done/closed issues",
    )
    my_parser.add_argument(
        "--priority", help="Filter by priority (e.g., High, Medium)"
    )
    my_parser.add_argument("--status", help="Filter by status (e.g., 'In Progress')")
    my_parser.add_argument(
        "-l", "--limit", type=int, default=50, help="Max results (default: 50)"
    )

    # Issue commands
    issue_parser = subparsers.add_parser("issue", help="Manage issues")
    issue_subparsers = issue_parser.add_subparsers(
        dest="issue_action", help="Issue action"
    )

    # issue create
    create_parser = issue_subparsers.add_parser("create", help="Create a new issue")
    create_parser.add_argument("project", help="Project key (e.g., DOPS)")
    create_parser.add_argument("summary", help="Issue summary/title")
    create_parser.add_argument(
        "--type", dest="issue_type", default="Task", help="Issue type (default: Task)"
    )
    create_parser.add_argument("--description", "-d", help="Issue description")
    create_parser.add_argument(
        "--parent", "-p", help="Parent issue key for sub-tasks (e.g., KEY-12345)"
    )
    create_parser.add_argument("--assignee", "-a", help="Assignee email/name")

    # issue update
    update_issue_parser = issue_subparsers.add_parser(
        "update", help="Update an existing issue"
    )
    update_issue_parser.add_argument("issue_key", help="Issue key (e.g., KEY-12345)")
    update_issue_parser.add_argument("--summary", "-s", help="New issue summary/title")
    update_issue_parser.add_argument(
        "--description", "-d", help="New issue description"
    )
    update_issue_parser.add_argument(
        "--assignee", "-a", help="New assignee (email/name)"
    )

    # issue view
    view_parser = issue_subparsers.add_parser("view", help="View issue details")
    view_parser.add_argument("issue_key", help="Issue key (e.g., KEY-12345)")

    # issue status
    status_parser = issue_subparsers.add_parser("status", help="Get issue status")
    status_parser.add_argument("issue_key", help="Issue key (e.g., KEY-12345)")

    # issue assign
    assign_parser = issue_subparsers.add_parser("assign", help="Assign/unassign issue")
    assign_parser.add_argument("issue_key", help="Issue key (e.g., KEY-12345)")
    assign_parser.add_argument("user", help="User email/name, or 'x' to unassign")

    # issue transition
    transition_parser = issue_subparsers.add_parser(
        "transition", help="Manage issue transitions"
    )
    transition_subparsers = transition_parser.add_subparsers(
        dest="transition_action", help="Transition action"
    )

    # issue transition list
    transition_list_parser = transition_subparsers.add_parser(
        "list", help="List available transitions"
    )
    transition_list_parser.add_argument("issue_key", help="Issue key (e.g., KEY-12345)")

    # issue transition fields
    transition_fields_parser = transition_subparsers.add_parser(
        "fields", help="List fields for a transition"
    )
    transition_fields_parser.add_argument(
        "issue_key", help="Issue key (e.g., KEY-12345)"
    )
    transition_fields_parser.add_argument(
        "transition_name", help="Transition name or ID"
    )

    # issue transition to
    transition_to_parser = transition_subparsers.add_parser(
        "to", help="Transition issue to a new status"
    )
    transition_to_parser.add_argument("issue_key", help="Issue key (e.g., KEY-12345)")
    transition_to_parser.add_argument(
        "transition_name", help="Transition name (e.g., 'In Progress', 'Done')"
    )
    transition_to_parser.add_argument(
        "--comment", "-c", help="Add a comment after transitioning"
    )
    transition_to_parser.add_argument(
        "--field",
        "-f",
        action="append",
        metavar="KEY=VALUE",
        help="Set field during transition (can be repeated)",
    )

    # issue comment
    comment_parser = issue_subparsers.add_parser(
        "comment", help="Manage issue comments"
    )
    comment_subparsers = comment_parser.add_subparsers(
        dest="comment_action", help="Comment action"
    )

    # issue comment list
    list_parser = comment_subparsers.add_parser(
        "list", help="List comments on an issue"
    )
    list_parser.add_argument("issue_key", help="Issue key (e.g., KEY-12345)")
    list_parser.add_argument("--last", type=int, help="Show only last N comments")
    list_parser.add_argument(
        "--order",
        choices=["asc", "desc"],
        default="desc",
        help="Sort order: asc (oldest first) or desc (newest first, default)",
    )

    # issue comment add
    add_parser = comment_subparsers.add_parser("add", help="Add a comment to an issue")
    add_parser.add_argument("issue_key", help="Issue key (e.g., KEY-12345)")
    add_parser.add_argument("body", help="Comment body text")

    # issue comment update
    update_parser = comment_subparsers.add_parser("update", help="Update a comment")
    update_parser.add_argument("issue_key", help="Issue key (e.g., KEY-12345)")
    update_parser.add_argument("comment_id", help="Comment ID")
    update_parser.add_argument("body", help="New comment body text")

    # issue comment delete
    delete_parser = comment_subparsers.add_parser("delete", help="Delete a comment")
    delete_parser.add_argument("issue_key", help="Issue key (e.g., KEY-12345)")
    delete_parser.add_argument("comment_id", help="Comment ID")

    args = parser.parse_args()

    # Handle commands
    if args.command == "filter":
        search_filters(args.query)
    elif args.command == "my":
        my_issues(
            scope=args.scope,
            project=args.project,
            exclude_done=not args.all_statuses,
            priority=args.priority,
            status=args.status,
            limit=args.limit,
        )
    elif args.command == "issue":
        if args.issue_action == "create":
            issue_create(
                args.project,
                args.summary,
                args.issue_type,
                args.description,
                args.parent,
                args.assignee,
            )
        elif args.issue_action == "update":
            issue_update(
                args.issue_key, args.summary, args.description, args.assignee
            )
        elif args.issue_action == "assign":
            issue_assign(args.issue_key, args.user)
        elif args.issue_action == "view":
            issue_view(args.issue_key)
        elif args.issue_action == "status":
            status_get(args.issue_key)
        elif args.issue_action == "transition":
            if args.transition_action == "list":
                transition_list(args.issue_key)
            elif args.transition_action == "fields":
                transition_fields(args.issue_key, args.transition_name)
            elif args.transition_action == "to":
                fields = None
                if args.field:
                    fields = {}
                    for f in args.field:
                        if "=" not in f:
                            print(
                                f"Error: Invalid field format '{f}'. Use KEY=VALUE",
                                file=sys.stderr,
                            )
                            sys.exit(1)
                        key, value = f.split("=", 1)
                        fields[key] = value
                transition_issue(
                    args.issue_key, args.transition_name, args.comment, fields
                )
            else:
                transition_parser.print_help()
        elif args.issue_action == "comment":
            if args.comment_action == "list":
                comment_list(args.issue_key, args.last, args.order)
            elif args.comment_action == "add":
                comment_add(args.issue_key, args.body)
            elif args.comment_action == "update":
                comment_update(args.issue_key, args.comment_id, args.body)
            elif args.comment_action == "delete":
                comment_delete(args.issue_key, args.comment_id)
            else:
                comment_parser.print_help()
        else:
            issue_parser.print_help()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
