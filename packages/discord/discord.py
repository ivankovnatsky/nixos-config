"""Shared Discord helpers.

Thin wrapper around the `discord-webhook` package so each consumer doesn't
re-encode the same `send` call. Future Discord-related helpers can land
in this module too.
"""

from __future__ import annotations

import platform
import sys

from discord_webhook import DiscordWebhook


def send_discord(
    webhook_url: str,
    message: str,
    *,
    source: str | None = None,
    user_agent: str = "discord-webhook/1.0",
    timeout: float = 10.0,
) -> bool:
    """Post a message to a Discord webhook.

    If `source` is provided, the message is prefixed with `**[source@hostname]** `
    matching the historical format used across packages. Returns True on success.
    """
    if source:
        hostname = platform.node()
        content = f"**[{source}@{hostname}]** {message}"
    else:
        content = message

    webhook = DiscordWebhook(
        url=webhook_url,
        content=content,
        timeout=timeout,
        user_agent=user_agent,
    )
    try:
        response = webhook.execute()
    except Exception as e:
        print(f"Discord notification failed: {e}", file=sys.stderr)
        return False

    if response is None:
        return False
    if hasattr(response, "ok") and not response.ok:
        print(
            f"Discord notification failed: HTTP {response.status_code} {response.text!r}",
            file=sys.stderr,
        )
        return False
    return True
