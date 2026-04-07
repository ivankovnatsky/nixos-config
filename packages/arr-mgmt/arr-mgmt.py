#!/usr/bin/env python3
"""
*arr stack management tool (Radarr, Sonarr, Lidarr, Prowlarr).
Declarative configuration via sync command.
"""

import sys
import json

import click

from sync import sync_lidarr, sync_radarr, sync_sonarr, sync_prowlarr


@click.group()
def cli():
    """*arr stack management tool (Radarr, Sonarr, Lidarr, Prowlarr)."""


@cli.command()
@click.option("--config-file", required=True, help="JSON configuration file")
@click.option(
    "--dry-run",
    is_flag=True,
    help="Show what would be changed without making changes",
)
def sync(config_file, dry_run):
    """Sync *arr configuration from JSON file."""
    try:
        with open(config_file, "r") as f:
            config = json.load(f)
    except Exception as e:
        click.echo(f"Error loading config file: {e}", err=True)
        sys.exit(1)

    try:
        if "lidarr" in config:
            sync_lidarr(config["lidarr"], dry_run=dry_run)

        if "radarr" in config:
            sync_radarr(config["radarr"], dry_run=dry_run)

        if "sonarr" in config:
            sync_sonarr(config["sonarr"], dry_run=dry_run)

        if "prowlarr" in config:
            sync_prowlarr(config["prowlarr"], dry_run=dry_run)

        if dry_run:
            click.echo("", err=True)
            click.echo("Dry-run complete - no changes made.", err=True)
        else:
            click.echo("", err=True)
            click.echo("Sync complete!", err=True)

    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


if __name__ == "__main__":
    cli(prog_name="arr-mgmt")
