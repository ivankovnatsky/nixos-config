"""Alerting via Discord webhooks."""

import json
import platform
import urllib.request

import click


def send_discord(webhook_url, message):
    hostname = platform.node()
    payload = json.dumps({"content": f"**[reposync@{hostname}]** {message}"}).encode()
    req = urllib.request.Request(
        webhook_url,
        data=payload,
        headers={"Content-Type": "application/json"},
    )
    try:
        urllib.request.urlopen(req, timeout=10)
    except Exception as e:
        click.echo(f"Discord notification failed: {e}", err=True)


def alert(webhook_url, message):
    click.echo(f"ALERT: {message}", err=True)
    if webhook_url:
        send_discord(webhook_url, message)
