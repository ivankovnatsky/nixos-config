"""CLI commands and argument parsing for jellyfin-mgmt."""

import sys
import json
import click

from client import JellyfinClient
from sync import sync_from_config


@click.group()
def main():
    """Jellyfin library management tool."""
    pass


@main.command("list")
@click.option("--base-url", required=True, help="Jellyfin URL")
@click.option("--api-key", required=True, help="API key")
@click.option(
    "--output-format",
    type=click.Choice(["table", "json"]),
    default="table",
    help="Output format",
)
def cmd_list(base_url, api_key, output_format):
    """List all libraries."""
    client = JellyfinClient(base_url, api_key)
    try:
        libraries = client.list_libraries()
        if output_format == "json":
            click.echo(json.dumps(libraries, indent=2))
        else:
            click.echo("Libraries:")
            for library in libraries:
                lib_id = library.get("ItemId", "N/A")
                name = library.get("Name", "Unknown")
                lib_type = library.get("CollectionType", "Unknown")
                click.echo(f"  {lib_id}: {name} ({lib_type})")
                if "Locations" in library and library["Locations"]:
                    click.echo("  Paths:")
                    for path in library["Locations"]:
                        click.echo(f"    - {path}")
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


@main.command("sync")
@click.option("--config-file", required=True, help="JSON configuration file")
@click.option(
    "--dry-run",
    is_flag=True,
    default=False,
    help="Show what would be changed without making changes",
)
def cmd_sync(config_file, dry_run):
    """Sync libraries from configuration file."""
    try:
        with open(config_file, "r") as f:
            config = json.load(f)
    except Exception as e:
        click.echo(f"Error loading config file: {e}", err=True)
        sys.exit(1)

    try:
        sync_from_config(config, dry_run=dry_run)

        if dry_run:
            click.echo("", err=True)
            click.echo("Dry-run complete - no changes made.", err=True)
        else:
            click.echo("", err=True)
            click.echo("Sync complete!", err=True)

    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)
