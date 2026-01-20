"""Release commands for jira-custom."""

import click

from ..client import get_jira_client


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


@click.group("release")
def release_group():
    """Manage releases"""
    pass


@release_group.command("list")
@click.argument("project")
def release_list_cmd(project):
    """List releases"""
    release_list_fn(project)
