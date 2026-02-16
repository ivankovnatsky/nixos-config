"""Comment commands for jira-custom."""

import click

from ..client import get_jira_client
from ..editor import edit_in_editor


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


def comment_edit_fn(issue_key, comment_id):
    """Edit a comment in $EDITOR"""
    jira = get_jira_client()
    comment = jira.comment(issue_key, comment_id)
    original = comment.body or ""

    new_text = edit_in_editor(original, suffix=f"-{issue_key}-comment-{comment_id}")

    if new_text == original:
        click.echo("No changes made", err=True)
        return

    comment.update(body=new_text)
    click.echo(f"Comment {comment_id} updated", err=True)


def comment_delete_fn(issue_key, comment_id):
    """Delete a comment"""
    jira = get_jira_client()
    comment = jira.comment(issue_key, comment_id)
    comment.delete()
    click.echo(f"Comment {comment_id} deleted successfully", err=True)


@click.group("comment")
def comment_group():
    """Manage issue comments"""
    pass


@comment_group.command("list")
@click.argument("issue_key")
@click.option("--last", type=int, help="Show only last N comments")
@click.option(
    "--order", type=click.Choice(["asc", "desc"]), default="desc", help="Sort order"
)
def comment_list_cmd(issue_key, last, order):
    """List comments on an issue"""
    comment_list_fn(issue_key, last, order)


@comment_group.command("add")
@click.argument("issue_key")
@click.argument("body", required=False)
@click.option("-e", "--editor", "use_editor", is_flag=True, help="Compose in $EDITOR")
def comment_add_cmd(issue_key, body, use_editor):
    """Add a comment to an issue"""
    if use_editor or body is None:
        body = edit_in_editor("", suffix=f"-{issue_key}-new-comment")
        if not body.strip():
            click.echo("Empty comment, aborting", err=True)
            return
    comment_add_fn(issue_key, body)


@comment_group.command("edit")
@click.argument("issue_key")
@click.argument("comment_id")
def comment_edit_cmd(issue_key, comment_id):
    """Edit a comment in $EDITOR"""
    comment_edit_fn(issue_key, comment_id)


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
