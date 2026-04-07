#!/usr/bin/env python3
"""
Syncthing configuration management tool.
Applies GUI credentials and device IDs via Syncthing REST API.
"""

import os
import sys
import logging

import click

from commands import cmd_list_devices, cmd_list_folders, cmd_status, cmd_scan
from sync import cmd_sync

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(message)s", stream=sys.stdout)


def _auto_detect_config_xml():
    """Try to find config.xml in common locations."""
    possible_configs = [
        # Linux (user)
        os.path.expanduser("~/.local/state/syncthing/config.xml"),
        os.path.expanduser("~/.config/syncthing/config.xml"),
        # Linux (system)
        "/var/lib/syncthing/.config/syncthing/config.xml",
        # Darwin (macOS)
        os.path.expanduser("~/Library/Application Support/Syncthing/config.xml"),
    ]
    for config_path in possible_configs:
        if os.path.exists(config_path):
            return config_path
    return None


# ---------------------------------------------------------------------------
# Common CLI options shared across cli sub-commands
# ---------------------------------------------------------------------------

_cli_options = [
    click.option(
        "--base-url",
        default=None,
        help="Syncthing URL (default: http://127.0.0.1:8384, with fallback to local IPs)",
    ),
    click.option("--api-key", default=None, help="Syncthing API key"),
    click.option(
        "--config-xml",
        default=None,
        help="Path to Syncthing config.xml (to extract API key)",
    ),
]


def add_cli_options(func):
    """Decorator that adds the common CLI connection options to a command."""
    for option in reversed(_cli_options):
        func = option(func)
    return func


def resolve_cli_args(base_url, api_key, config_xml):
    """
    Apply CLI-mode defaults: auto-detect config.xml and default base_url.
    Returns (base_url, api_key, config_xml).
    """
    if not config_xml and not api_key:
        config_xml = _auto_detect_config_xml()
    if not base_url:
        base_url = "http://127.0.0.1:8384"
    return base_url, api_key, config_xml


# ---------------------------------------------------------------------------
# Top-level group
# ---------------------------------------------------------------------------


@click.group(invoke_without_command=True)
@click.pass_context
def cli(ctx):
    """Syncthing configuration management tool.

    Default mode: CLI (use 'syncthing-mgmt' or 'syncthing-mgmt cli status')
    """
    if ctx.invoked_subcommand is None:
        # Default: cli status
        base_url, api_key, config_xml = resolve_cli_args(None, None, None)
        cmd_status(
            base_url=base_url, api_key=api_key, config_xml=config_xml, mode="cli"
        )


# ---------------------------------------------------------------------------
# CLI mode group
# ---------------------------------------------------------------------------


@cli.group("cli", invoke_without_command=True)
@click.pass_context
def cli_group(ctx):
    """CLI mode for interactive use (default)."""
    if ctx.invoked_subcommand is None:
        # Default cli sub-command is status
        base_url, api_key, config_xml = resolve_cli_args(None, None, None)
        cmd_status(
            base_url=base_url, api_key=api_key, config_xml=config_xml, mode="cli"
        )


@cli_group.command("status")
@add_cli_options
def cli_status(base_url, api_key, config_xml):
    """Show status of configured devices and folders (default)."""
    base_url, api_key, config_xml = resolve_cli_args(base_url, api_key, config_xml)
    cmd_status(base_url=base_url, api_key=api_key, config_xml=config_xml, mode="cli")


@cli_group.command("scan")
@add_cli_options
@click.argument("folders", nargs=-1, required=False)
def cli_scan(base_url, api_key, config_xml, folders):
    """Trigger a rescan for one or more folders."""
    base_url, api_key, config_xml = resolve_cli_args(base_url, api_key, config_xml)
    cmd_scan(
        base_url=base_url,
        api_key=api_key,
        config_xml=config_xml,
        mode="cli",
        folders=list(folders),
    )


@cli_group.group("list")
def cli_list():
    """List configured resources."""


@cli_list.command("devices")
@add_cli_options
def cli_list_devices(base_url, api_key, config_xml):
    """List all configured devices."""
    base_url, api_key, config_xml = resolve_cli_args(base_url, api_key, config_xml)
    cmd_list_devices(
        base_url=base_url, api_key=api_key, config_xml=config_xml, mode="cli"
    )


@cli_list.command("folders")
@add_cli_options
def cli_list_folders(base_url, api_key, config_xml):
    """List all configured folders."""
    base_url, api_key, config_xml = resolve_cli_args(base_url, api_key, config_xml)
    cmd_list_folders(
        base_url=base_url, api_key=api_key, config_xml=config_xml, mode="cli"
    )


# ---------------------------------------------------------------------------
# Declarative mode command
# ---------------------------------------------------------------------------


@cli.command("declarative")
@click.option("--base-url", required=True, help="Syncthing URL")
@click.option("--api-key", default=None, help="Syncthing API key")
@click.option(
    "--config-xml",
    default=None,
    help="Path to Syncthing config.xml (to extract API key)",
)
@click.option("--config-file", required=True, help="JSON configuration file")
@click.option(
    "--dry-run",
    is_flag=True,
    default=False,
    help="Show what would be changed without making changes",
)
@click.option(
    "--restart",
    is_flag=True,
    default=False,
    help="Restart Syncthing after applying changes",
)
def declarative(base_url, api_key, config_xml, config_file, dry_run, restart):
    """Declarative mode for NixOS/Darwin modules."""
    cmd_sync(
        base_url=base_url,
        api_key=api_key,
        config_xml=config_xml,
        config_file=config_file,
        dry_run=dry_run,
        restart=restart,
    )


if __name__ == "__main__":
    cli(prog_name="syncthing-mgmt")
