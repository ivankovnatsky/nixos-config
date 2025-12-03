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


def comment_list(issue_key):
    """List all comments on an issue"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)
    comments = jira.comments(issue)

    if not comments:
        print(f"No comments on {issue_key}")
        return

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


def issue_create(project, summary, issue_type="Task", description=None, parent=None):
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
    issue = jira.create_issue(fields=fields)
    print(issue.key)


def desc_get(issue_key):
    """Get issue description"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)
    description = issue.fields.description or ""
    print(description)


def desc_update(issue_key, body):
    """Update issue description"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)
    issue.update(fields={"description": body})
    print(f"Description updated for {issue_key}", file=sys.stderr)


def status_get(issue_key):
    """Get issue status"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)
    print(issue.fields.status.name)


def transition_list(issue_key):
    """List available transitions for an issue"""
    jira = get_jira_client()
    transitions = jira.transitions(issue_key)
    for t in transitions:
        print(f"{t['id']}: {t['name']}")


def transition_issue(issue_key, transition_name):
    """Transition an issue to a new status"""
    jira = get_jira_client()
    jira.transition_issue(issue_key, transition_name)
    issue = jira.issue(issue_key)
    print(f"Transitioned to: {issue.fields.status.name}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description="Custom JIRA operations")
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Filter command
    filter_parser = subparsers.add_parser("filter", help="Search for JIRA filters")
    filter_parser.add_argument("query", nargs="?", help="Filter name query")

    # Issue commands
    issue_parser = subparsers.add_parser("issue", help="Manage issues")
    issue_subparsers = issue_parser.add_subparsers(dest="issue_action", help="Issue action")

    # issue create
    create_parser = issue_subparsers.add_parser("create", help="Create a new issue")
    create_parser.add_argument("project", help="Project key (e.g., DOPS)")
    create_parser.add_argument("summary", help="Issue summary/title")
    create_parser.add_argument("--type", dest="issue_type", default="Task", help="Issue type (default: Task)")
    create_parser.add_argument("--description", "-d", help="Issue description")
    create_parser.add_argument("--parent", "-p", help="Parent issue key for sub-tasks (e.g., DOPS-12345)")

    # issue desc
    desc_parser = issue_subparsers.add_parser("desc", help="Manage issue description")
    desc_subparsers = desc_parser.add_subparsers(dest="desc_action", help="Description action")

    # issue desc get
    desc_get_parser = desc_subparsers.add_parser("get", help="Get issue description")
    desc_get_parser.add_argument("issue_key", help="Issue key (e.g., DOPS-12345)")

    # issue desc update
    desc_update_parser = desc_subparsers.add_parser("update", help="Update issue description")
    desc_update_parser.add_argument("issue_key", help="Issue key (e.g., DOPS-12345)")
    desc_update_parser.add_argument("body", help="New description text")

    # issue status
    status_parser = issue_subparsers.add_parser("status", help="Get issue status")
    status_parser.add_argument("issue_key", help="Issue key (e.g., DOPS-12345)")

    # issue transition
    transition_parser = issue_subparsers.add_parser("transition", help="Transition an issue")
    transition_parser.add_argument("issue_key", help="Issue key (e.g., DOPS-12345)")
    transition_parser.add_argument("transition_name", help="Transition name (e.g., 'In Progress', 'Done')")

    # issue transitions (list available)
    transitions_parser = issue_subparsers.add_parser("transitions", help="List available transitions for an issue")
    transitions_parser.add_argument("issue_key", help="Issue key (e.g., DOPS-12345)")

    # issue comment
    comment_parser = issue_subparsers.add_parser("comment", help="Manage issue comments")
    comment_subparsers = comment_parser.add_subparsers(dest="comment_action", help="Comment action")

    # issue comment list
    list_parser = comment_subparsers.add_parser("list", help="List comments on an issue")
    list_parser.add_argument("issue_key", help="Issue key (e.g., DOPS-12345)")

    # issue comment add
    add_parser = comment_subparsers.add_parser("add", help="Add a comment to an issue")
    add_parser.add_argument("issue_key", help="Issue key (e.g., DOPS-12345)")
    add_parser.add_argument("body", help="Comment body text")

    # issue comment update
    update_parser = comment_subparsers.add_parser("update", help="Update a comment")
    update_parser.add_argument("issue_key", help="Issue key (e.g., DOPS-12345)")
    update_parser.add_argument("comment_id", help="Comment ID")
    update_parser.add_argument("body", help="New comment body text")

    # issue comment delete
    delete_parser = comment_subparsers.add_parser("delete", help="Delete a comment")
    delete_parser.add_argument("issue_key", help="Issue key (e.g., DOPS-12345)")
    delete_parser.add_argument("comment_id", help="Comment ID")

    args = parser.parse_args()

    # Handle commands
    if args.command == "filter":
        search_filters(args.query)
    elif args.command == "issue":
        if args.issue_action == "create":
            issue_create(args.project, args.summary, args.issue_type, args.description, args.parent)
        elif args.issue_action == "desc":
            if args.desc_action == "get":
                desc_get(args.issue_key)
            elif args.desc_action == "update":
                desc_update(args.issue_key, args.body)
            else:
                desc_parser.print_help()
        elif args.issue_action == "status":
            status_get(args.issue_key)
        elif args.issue_action == "transition":
            transition_issue(args.issue_key, args.transition_name)
        elif args.issue_action == "transitions":
            transition_list(args.issue_key)
        elif args.issue_action == "comment":
            if args.comment_action == "list":
                comment_list(args.issue_key)
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
