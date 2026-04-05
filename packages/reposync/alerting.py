"""Alerting via Discord webhooks."""

import json
import platform
import sys
import urllib.request


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
        print(f"Discord notification failed: {e}", file=sys.stderr)


def alert(webhook_url, message):
    print(f"ALERT: {message}", file=sys.stderr)
    if webhook_url:
        send_discord(webhook_url, message)
