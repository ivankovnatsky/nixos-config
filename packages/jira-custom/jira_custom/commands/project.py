"""Project commands for jira-custom."""

import click

from ..client import get_jira_client


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


@click.group("project")
def project_group():
    """Manage projects"""
    pass


@project_group.command("list")
def project_list_cmd():
    """List projects"""
    project_list_fn()
