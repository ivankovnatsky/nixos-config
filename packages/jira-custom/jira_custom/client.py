"""JIRA client initialization."""

import os
import click
from jira import JIRA


def get_jira_client():
    """Get authenticated JIRA client"""
    server = os.getenv("JIRA_SERVER")
    email = os.getenv("JIRA_EMAIL")
    token = os.getenv("JIRA_API_TOKEN")

    if not all([server, email, token]):
        raise click.ClickException(
            "Set JIRA_SERVER, JIRA_EMAIL, and JIRA_API_TOKEN in environment"
        )

    return JIRA(server=server, basic_auth=(email, token))
