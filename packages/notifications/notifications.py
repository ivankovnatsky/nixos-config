"""Send notifications to external channels.

Subcommands:
  battery   Send current battery state to a Discord webhook.
"""

from __future__ import annotations

import json
import os
import sys
from datetime import datetime, time, timedelta
from pathlib import Path

import click

import battery as settings_battery
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


def default_state_path() -> Path:
    base = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local" / "state")
    return Path(base) / "notifications" / "battery.json"


def load_state(path: Path) -> dict:
    try:
        with path.open() as fh:
            return json.load(fh)
    except FileNotFoundError:
        return {}
    except (OSError, json.JSONDecodeError) as e:
        click.echo(f"Warning: ignoring unreadable state file {path}: {e}", err=True)
        return {}


def save_state(path: Path, state: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w") as fh:
        json.dump(state, fh)
    tmp.replace(path)


def parse_hhmm(value: str) -> time:
    try:
        return datetime.strptime(value, "%H:%M").time()
    except ValueError as e:
        raise click.BadParameter(f"--daily-at must be HH:MM, got {value!r}") from e


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
@click.option(
    "--daily-at",
    default="",
    metavar="HH:MM",
    help="Send a daily notification at or after this time (once per day). Empty disables.",
)
@click.option(
    "--below-percent",
    type=int,
    default=0,
    metavar="N",
    help="Also send when battery <= N percent and discharging. 0 disables.",
)
@click.option(
    "--low-interval-hours",
    type=float,
    default=3.0,
    show_default=True,
    help="Minimum hours between repeated low-battery notifications.",
)
@click.option(
    "--state-file",
    type=click.Path(dir_okay=False, writable=True),
    default=None,
    help="State file used to dedupe sends (default: $XDG_STATE_HOME/notifications/battery.json).",
)
def battery(
    webhook,
    webhook_file,
    dry_run,
    daily_at,
    below_percent,
    low_interval_hours,
    state_file,
):
    """Send current battery state to a Discord webhook.

    Without --daily-at or --below-percent, sends every invocation. With
    either flag set, the script only sends when its conditions match and
    tracks dedupe state in --state-file.
    """
    info = settings_battery.battery_get()

    if info is None:
        click.echo("No battery detected; nothing to notify.")
        return

    daily_at_enabled = bool(daily_at)
    below_percent_enabled = below_percent > 0
    conditional = daily_at_enabled or below_percent_enabled
    state_path = Path(state_file) if state_file else default_state_path()
    state = load_state(state_path) if conditional else {}
    now = datetime.now()
    today = now.date()

    reasons: list[str] = []

    if daily_at_enabled:
        target = parse_hhmm(daily_at)
        last_daily = state.get("last_daily_date")
        crossed = now.time() >= target
        already_sent_today = last_daily == today.isoformat()
        if crossed and not already_sent_today:
            reasons.append(f"daily@{daily_at}")

    if below_percent_enabled:
        percent = info.get("percent")
        is_discharging = info.get("state") == "discharging"
        if (
            isinstance(percent, (int, float))
            and percent <= below_percent
            and is_discharging
        ):
            last_low = state.get("last_low_ts")
            try:
                last_low_dt = datetime.fromisoformat(last_low) if last_low else None
            except ValueError:
                last_low_dt = None
            if last_low_dt is None or now - last_low_dt >= timedelta(
                hours=low_interval_hours
            ):
                reasons.append(f"low<={below_percent}%")

    if conditional and not reasons:
        click.echo("No notification condition met; skipping.")
        return

    suffix = f" ({', '.join(reasons)})" if reasons else ""
    message = f"Battery: {settings_battery.format_human(info)}{suffix}"

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

    if conditional:
        if any(r.startswith("daily@") for r in reasons):
            state["last_daily_date"] = today.isoformat()
        if any(r.startswith("low<=") for r in reasons):
            state["last_low_ts"] = now.isoformat(timespec="seconds")
        try:
            save_state(state_path, state)
        except OSError as e:
            click.echo(
                f"Warning: could not write state file {state_path}: {e}", err=True
            )

    click.echo(f"Sent: {message}")


if __name__ == "__main__":
    cli(prog_name="notifications")
