"""Main CLI entry point for jira-custom."""

import sys
import click

from .commands import (
    filter_cmd,
    open_cmd,
    me_cmd,
    serverinfo_cmd,
    project_group,
    release_group,
    sprint_group,
    epic_group,
    board_group,
    issue_group,
    my_cmd,
)

# Fix program name in usage output when run via Nix store path
sys.argv[0] = "jira-custom"


@click.group(context_settings={"help_option_names": ["-h", "--help"]})
def cli():
    """Custom JIRA operations"""
    pass


# Register top-level commands
cli.add_command(filter_cmd)
cli.add_command(my_cmd)
cli.add_command(open_cmd)
cli.add_command(me_cmd)
cli.add_command(serverinfo_cmd)

# Register command groups
cli.add_command(sprint_group)
cli.add_command(epic_group)
cli.add_command(board_group)
cli.add_command(project_group)
cli.add_command(release_group)
cli.add_command(issue_group)
