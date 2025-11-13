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


def main():
    parser = argparse.ArgumentParser(description="Custom JIRA operations")
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Filter command
    filter_parser = subparsers.add_parser("filter", help="Search for JIRA filters")
    filter_parser.add_argument("query", nargs="?", help="Filter name query")

    # Comment commands
    comment_parser = subparsers.add_parser("comment", help="Manage issue comments")
    comment_subparsers = comment_parser.add_subparsers(
        dest="comment_action", help="Comment action"
    )

    # comment list
    list_parser = comment_subparsers.add_parser(
        "list", help="List comments on an issue"
    )
    list_parser.add_argument("issue_key", help="Issue key (e.g., DOPS-12345)")

    # comment add
    add_parser = comment_subparsers.add_parser("add", help="Add a comment to an issue")
    add_parser.add_argument("issue_key", help="Issue key (e.g., DOPS-12345)")
    add_parser.add_argument("body", help="Comment body text")

    # comment update
    update_parser = comment_subparsers.add_parser("update", help="Update a comment")
    update_parser.add_argument("issue_key", help="Issue key (e.g., DOPS-12345)")
    update_parser.add_argument("comment_id", help="Comment ID")
    update_parser.add_argument("body", help="New comment body text")

    # comment delete
    delete_parser = comment_subparsers.add_parser("delete", help="Delete a comment")
    delete_parser.add_argument("issue_key", help="Issue key (e.g., DOPS-12345)")
    delete_parser.add_argument("comment_id", help="Comment ID")

    args = parser.parse_args()

    # Handle commands
    if args.command == "filter":
        search_filters(args.query)
    elif args.command == "comment":
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
        # Backward compatibility: if no subcommand, treat as filter search
        if len(sys.argv) > 1:
            search_filters(sys.argv[1])
        else:
            parser.print_help()


if __name__ == "__main__":
    main()
