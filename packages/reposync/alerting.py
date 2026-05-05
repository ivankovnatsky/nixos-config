"""Alerting via Discord webhooks."""

import click

from discord import send_discord as _send_discord


def send_discord(webhook_url, message):
    _send_discord(webhook_url, message, source="reposync", user_agent="reposync/1.0")


def alert(webhook_url, message):
    click.echo(f"ALERT: {message}", err=True)
    if webhook_url:
        send_discord(webhook_url, message)
