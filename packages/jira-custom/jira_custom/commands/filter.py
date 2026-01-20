"""Filter command for jira-custom."""

import click

from ..client import get_jira_client


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


@click.command("filter")
@click.argument("query", required=False)
def filter_cmd(query):
    """Search for JIRA filters"""
    search_filters_fn(query)
