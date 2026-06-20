"""Send notifications to external channels.

Subcommands:
  battery        Send current battery state to a Discord webhook.
  digest-flush   Post all pending digest notifications (run daily at 21:00).
"""

from __future__ import annotations

import sys

import click

import battery as settings_battery
import digest
from discord import send_discord as _send_discord


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
    return _send_discord(
        webhook_url, message, source=source, user_agent="notifications/1.0"
    )


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
    info = settings_battery.battery_get()

    if info is None:
        click.echo("No battery detected; nothing to notify.")
        return

    message = f"Battery: {settings_battery.format_human(info)}"

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


@cli.command(name="digest-flush")
@click.option(
    "--state-file",
    type=click.Path(dir_okay=False),
    help="Path to the shared digest state file (defaults to the platform path).",
)
def digest_flush(state_file):
    """Post all pending digest notifications and clear the ones that were sent.

    Producers (reposync, rebuild) record failures here instead of alerting
    immediately; this command — scheduled daily at 21:00 — posts whatever is
    still pending. Anything cleared by a producer before now is dropped
    silently. The webhook URL for each entry is read from the webhook file the
    producer recorded.
    """

    def _send(webhook_url, content):
        # Content is already fully formatted (incl. any [source@host] prefix).
        return _send_discord(webhook_url, content, user_agent="notifications/1.0")

    digest.flush(_send, state_file=state_file, log=lambda m: click.echo(m, err=True))


if __name__ == "__main__":
    cli(prog_name="notifications")
