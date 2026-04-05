"""CLI argument parsing and main entry point for uptime-kuma-mgmt."""

import os
import sys

import click
from uptime_kuma_api import UptimeKumaException

from auth import read_secret
from client import UptimeKumaClient
from commands import cmd_list, cmd_get, cmd_sync
from constants import (
    ENV_BASE_URL,
    ENV_USERNAME,
    ENV_PASSWORD,
    DEFAULT_USERNAME_PATH,
    DEFAULT_PASSWORD_PATH,
)


def auth_options(f):
    """Decorator that adds common authentication options to a command."""
    f = click.option(
        "--password",
        default=lambda: read_secret(ENV_PASSWORD, DEFAULT_PASSWORD_PATH),
        help=f"Password (or set {ENV_PASSWORD}, default: {DEFAULT_PASSWORD_PATH})",
    )(f)
    f = click.option(
        "--username",
        default=lambda: read_secret(ENV_USERNAME, DEFAULT_USERNAME_PATH),
        help=f"Username (or set {ENV_USERNAME}, default: {DEFAULT_USERNAME_PATH})",
    )(f)
    f = click.option(
        "--base-url",
        default=lambda: os.environ.get(ENV_BASE_URL),
        help=f"Uptime Kuma base URL (or set {ENV_BASE_URL})",
    )(f)
    return f


def validate_auth(base_url, username, password):
    """Validate that all required auth arguments are provided."""
    missing = []
    if not base_url:
        missing.append(f"--base-url or {ENV_BASE_URL}")
    if not username:
        missing.append(f"--username or {ENV_USERNAME}")
    if not password:
        missing.append(f"--password or {ENV_PASSWORD}")
    if missing:
        raise click.UsageError(f"Missing required arguments: {', '.join(missing)}")


@click.group()
def main():
    """Uptime Kuma monitor management tool."""


@main.command("list")
@auth_options
@click.option(
    "--output-format",
    type=click.Choice(["table", "json"]),
    default="table",
    help="Output format",
)
def cmd_list_cli(base_url, username, password, output_format):
    """List all monitors."""
    validate_auth(base_url, username, password)
    try:
        with UptimeKumaClient(base_url, username, password) as client:
            cmd_list(output_format, client)
    except UptimeKumaException:
        click.echo(f"Error: Failed to connect to Uptime Kuma at {base_url}", err=True)
        click.echo("  Please verify the server is running and accessible.", err=True)
        sys.exit(1)
    except Exception as e:
        _handle_exception(e, base_url)


@main.command("get")
@auth_options
@click.option("--monitor-id", required=True, type=int, help="Monitor ID")
def cmd_get_cli(base_url, username, password, monitor_id):
    """Get monitor details."""
    validate_auth(base_url, username, password)
    try:
        with UptimeKumaClient(base_url, username, password) as client:
            cmd_get(monitor_id, client)
    except UptimeKumaException:
        click.echo(f"Error: Failed to connect to Uptime Kuma at {base_url}", err=True)
        click.echo("  Please verify the server is running and accessible.", err=True)
        sys.exit(1)
    except Exception as e:
        _handle_exception(e, base_url)


@main.command("sync")
@auth_options
@click.option("--config-file", required=True, help="JSON configuration file")
@click.option(
    "--discord-webhook", default=None, help="Discord webhook URL for notifications"
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Show what would be changed without making changes",
)
def cmd_sync_cli(base_url, username, password, config_file, discord_webhook, dry_run):
    """Sync monitors from configuration file."""
    validate_auth(base_url, username, password)
    try:
        with UptimeKumaClient(base_url, username, password) as client:
            cmd_sync(config_file, dry_run, discord_webhook, client)
    except UptimeKumaException:
        click.echo(f"Error: Failed to connect to Uptime Kuma at {base_url}", err=True)
        click.echo("  Please verify the server is running and accessible.", err=True)
        sys.exit(1)
    except Exception as e:
        _handle_exception(e, base_url)


def _handle_exception(e, base_url):
    """Handle generic exceptions with connection-aware messaging."""
    error_msg = str(e)
    if "Connection refused" in error_msg or "unable to connect" in error_msg.lower():
        click.echo(f"Error: Failed to connect to Uptime Kuma at {base_url}", err=True)
        click.echo("  Please verify the server is running and accessible.", err=True)
    else:
        click.echo(f"Error: {e}", err=True)
    sys.exit(1)
