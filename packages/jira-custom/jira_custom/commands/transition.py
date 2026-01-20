"""Transition commands for jira-custom."""

import sys
import os
import webbrowser
import click

from ..client import get_jira_client
from ..utils import parse_fields


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


@click.group("transition")
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
