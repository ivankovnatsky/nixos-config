"""User commands for jira-custom."""

import os
import webbrowser
import click

from ..client import get_jira_client


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
    click.echo(
        f"Account:  {user.accountId if hasattr(user, 'accountId') else user.name}"
    )
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


@click.command("open")
@click.argument("issue_key", required=False)
def open_cmd(issue_key):
    """Open issue in browser"""
    open_issue_fn(issue_key)


@click.command("me")
def me_cmd():
    """Show current user"""
    show_me_fn()


@click.command("serverinfo")
def serverinfo_cmd():
    """Show server info"""
    show_serverinfo_fn()
