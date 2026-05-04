#!/usr/bin/env python3
"""Send notifications to external channels.

Subcommands:
  battery   Send current battery state to a Discord webhook.
"""

from __future__ import annotations

import json
import platform
import subprocess
import sys
import urllib.error
import urllib.request

import click


def read_webhook(webhook: str | None, webhook_file: str | None) -> str | None:
    if webhook:
        return webhook.strip()
    if webhook_file:
        try:
            with open(webhook_file) as fh:
                return fh.read().strip()
        except OSError as e:
            click.echo(f"Could not read webhook file {webhook_file}: {e}", err=True)
            return None
    return None


def send_discord(webhook_url: str, message: str, source: str) -> bool:
    """Post a message to a Discord webhook. Returns True on success."""
    hostname = platform.node()
    payload = json.dumps({"content": f"**[{source}@{hostname}]** {message}"}).encode()
    req = urllib.request.Request(
        webhook_url,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "User-Agent": "notifications/1.0",
        },
    )
    try:
        urllib.request.urlopen(req, timeout=10)
        return True
    except (urllib.error.URLError, urllib.error.HTTPError, OSError) as e:
        click.echo(f"Discord notification failed: {e}", err=True)
        return False


def get_battery_state() -> dict | None:
    """Read battery state by shelling out to `settings battery --json`."""
    try:
        result = subprocess.run(
            ["settings", "battery", "--json"],
            capture_output=True,
            text=True,
            check=True,
        )
    except FileNotFoundError:
        click.echo("`settings` CLI not found in PATH", err=True)
        return None
    except subprocess.CalledProcessError as e:
        msg = (e.stderr or "").strip() or f"exit {e.returncode}"
        click.echo(f"`settings battery --json` failed: {msg}", err=True)
        return None

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as e:
        click.echo(f"Could not parse settings battery output: {e}", err=True)
        return None


def format_battery(info: dict) -> str:
    parts = []
    if info.get("percent") is not None:
        parts.append(f"{info['percent']}%")
    state = info.get("state")
    if state and state != "unknown":
        parts.append(state)
    if info.get("time_remaining"):
        parts.append(f"{info['time_remaining']} remaining")
    if info.get("source"):
        parts.append(f"on {info['source']}")
    return ", ".join(parts) if parts else "unknown"


@click.group(invoke_without_command=True)
@click.pass_context
def cli(ctx):
    """Send notifications to external channels."""
    if ctx.invoked_subcommand is None:
        click.echo(ctx.get_help())


@cli.command()
@click.option(
    "--webhook",
    envvar="NOTIFICATIONS_DISCORD_WEBHOOK",
    help="Discord webhook URL (or set NOTIFICATIONS_DISCORD_WEBHOOK).",
)
@click.option(
    "--webhook-file",
    type=click.Path(exists=True, dir_okay=False, readable=True),
    help="Path to a file containing the Discord webhook URL.",
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Print the message instead of sending it.",
)
def battery(webhook, webhook_file, dry_run):
    """Send current battery state to a Discord webhook."""
    info = get_battery_state()
    if info is None:
        sys.exit(1)

    message = f"Battery: {format_battery(info)}"

    if dry_run:
        click.echo(message)
        return

    url = read_webhook(webhook, webhook_file)
    if not url:
        click.echo(
            "No Discord webhook configured. Pass --webhook, --webhook-file, "
            "or set NOTIFICATIONS_DISCORD_WEBHOOK.",
            err=True,
        )
        sys.exit(1)

    if not send_discord(url, message, source="notifications"):
        sys.exit(1)
    click.echo(f"Sent: {message}")


if __name__ == "__main__":
    cli(prog_name="notifications")
    sys.exit(0)
