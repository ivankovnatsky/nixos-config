"""Attachment commands for jira-custom."""

import os
import click

from ..client import get_jira_client
from ..utils import ISSUE_KEY


def attachment_list_fn(issue_key):
    """List attachments on an issue"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)
    attachments = issue.fields.attachment

    if not attachments:
        click.echo(f"No attachments on {issue_key}")
        return

    for att in attachments:
        size = int(att.size)
        if size >= 1024 * 1024:
            size_str = f"{size / (1024 * 1024):.1f} MB"
        elif size >= 1024:
            size_str = f"{size / 1024:.1f} KB"
        else:
            size_str = f"{size} B"

        click.echo(f"ID: {att.id}")
        click.echo(f"Filename: {att.filename}")
        click.echo(f"Size: {size_str}")
        click.echo(f"MIME: {att.mimeType}")
        click.echo(f"Author: {att.author.displayName}")
        click.echo(f"Created: {att.created}")
        click.echo("-" * 60)


def attachment_download_fn(issue_key, attachment_id=None, output_dir="."):
    """Download attachments from an issue"""
    jira = get_jira_client()
    issue = jira.issue(issue_key)
    attachments = issue.fields.attachment

    if not attachments:
        click.echo(f"No attachments on {issue_key}")
        return

    if attachment_id:
        attachments = [a for a in attachments if a.id == attachment_id]
        if not attachments:
            raise click.ClickException(
                f"Attachment {attachment_id} not found on {issue_key}"
            )

    os.makedirs(output_dir, exist_ok=True)

    for att in attachments:
        filepath = os.path.join(output_dir, att.filename)
        content = att.get()
        with open(filepath, "wb") as f:
            f.write(content)
        click.echo(f"Downloaded: {filepath}", err=True)


def attachment_add_fn(issue_key, filepaths):
    """Add attachments to an issue"""
    jira = get_jira_client()

    for filepath in filepaths:
        if not os.path.exists(filepath):
            raise click.ClickException(f"File not found: {filepath}")

    for filepath in filepaths:
        att = jira.add_attachment(issue_key, filepath)
        click.echo(f"{att.id}")


def attachment_delete_fn(issue_key, attachment_id):
    """Delete an attachment"""
    jira = get_jira_client()
    jira.delete_attachment(attachment_id)
    click.echo(f"Attachment {attachment_id} deleted from {issue_key}", err=True)


@click.group("attachment")
def attachment_group():
    """Manage issue attachments"""
    pass


@attachment_group.command("list")
@click.argument("issue_key", type=ISSUE_KEY)
def attachment_list_cmd(issue_key):
    """List attachments on an issue"""
    attachment_list_fn(issue_key)


@attachment_group.command("download")
@click.argument("issue_key", type=ISSUE_KEY)
@click.option("--id", "attachment_id", help="Download specific attachment by ID")
@click.option(
    "-o", "--output", "output_dir", default=".", help="Output directory (default: .)"
)
def attachment_download_cmd(issue_key, attachment_id, output_dir):
    """Download attachments from an issue

    Examples:

      # Download all attachments
      jira-custom issue attachment download PROJ-123

      # Download specific attachment
      jira-custom issue attachment download PROJ-123 --id 12345

      # Download to specific directory
      jira-custom issue attachment download PROJ-123 -o ./attachments
    """
    attachment_download_fn(issue_key, attachment_id, output_dir)


@attachment_group.command("add")
@click.argument("issue_key", type=ISSUE_KEY)
@click.argument("files", nargs=-1, required=True, type=click.Path(exists=True))
def attachment_add_cmd(issue_key, files):
    """Add attachments to an issue

    Examples:

      # Add a single file
      jira-custom issue attachment add PROJ-123 report.pdf

      # Add multiple files
      jira-custom issue attachment add PROJ-123 file1.pdf file2.png
    """
    attachment_add_fn(issue_key, list(files))


@attachment_group.command("delete")
@click.argument("issue_key", type=ISSUE_KEY)
@click.argument("attachment_id")
def attachment_delete_cmd(issue_key, attachment_id):
    """Delete an attachment"""
    attachment_delete_fn(issue_key, attachment_id)
