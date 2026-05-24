"""Alerting via Discord webhooks."""

import fcntl
import hashlib
import json
import os
import sys
import time
from contextlib import contextmanager
from pathlib import Path

import click

from discord import send_discord as _send_discord

DEFAULT_ALERT_REPEAT_SECONDS = 3 * 60 * 60

_repeat_seconds = DEFAULT_ALERT_REPEAT_SECONDS
_state_file = None


def configure_alerts(repeat_seconds=None, state_file=None):
    global _repeat_seconds, _state_file

    if repeat_seconds is not None:
        try:
            _repeat_seconds = max(0, int(repeat_seconds))
        except (TypeError, ValueError):
            raise click.ClickException("alertRepeatSeconds must be an integer")

    if state_file:
        _state_file = Path(state_file)


def send_discord(webhook_url, message):
    return _send_discord(
        webhook_url,
        message,
        source="reposync",
        user_agent="reposync/1.0",
    )


def alert(webhook_url, message):
    click.echo(f"ALERT: {message}", err=True)
    if not webhook_url:
        return

    should_send, remaining, key = _should_send(message)
    if not should_send:
        click.echo(
            f"Discord alert suppressed; next repeat in {_format_duration(remaining)}.",
            err=True,
        )
        return

    if send_discord(webhook_url, message):
        _record_sent(key, message)


def clear_alerts_for_repo(repo_name):
    """Clear suppression state for all alerts associated with a specific repository.

    This is called when a repository syncs successfully, ensuring that any
    subsequent failure will trigger an immediate alert.
    """
    prefix = f"`{repo_name}`:"
    with _locked_state() as state:
        alerts = state.get("alerts", {})
        to_remove = [
            k for k, v in alerts.items() if v.get("message", "").startswith(prefix)
        ]
        for k in to_remove:
            del alerts[k]


def _should_send(message):
    if _repeat_seconds <= 0:
        return True, 0, None

    now = time.time()
    key = _alert_key(message)

    with _locked_state() as state:
        alert_info = state.get("alerts", {}).get(key)
        if not alert_info:
            return True, 0, key

        last_sent = alert_info.get("last_sent")
        if last_sent is None:
            return True, 0, key

        elapsed = now - last_sent
        if elapsed >= _repeat_seconds:
            return True, 0, key

        return False, _repeat_seconds - elapsed, key


def _record_sent(key, message):
    if key is None:
        return

    # Message stabilization: strip volatile details (after " — ") to create a stable key.
    # We store the stable message to allow granular clearing by repository name.
    stable_message = message.rsplit(" — ", 1)[0]

    with _locked_state() as state:
        alerts = state.setdefault("alerts", {})
        alerts[key] = {
            "last_sent": time.time(),
            "message": stable_message,
        }


def _alert_key(message):
    # Message stabilization: strip volatile details (after " — ") to create a stable key.
    # This ensures that "fetch failed — [connection timeout]" and "fetch failed — [auth error]"
    # are treated as the same alert for suppression purposes.
    stable_message = message.rsplit(" — ", 1)[0]
    return hashlib.sha256(stable_message.encode("utf-8")).hexdigest()


def _state_path():
    if _state_file is not None:
        return _state_file

    env_path = os.environ.get("REPOSYNC_ALERT_STATE_FILE")
    if env_path:
        return Path(env_path)

    if sys.platform == "darwin":
        return (
            Path.home() / "Library" / "Application Support" / "reposync" / "alerts.json"
        )

    state_home = os.environ.get("XDG_STATE_HOME")
    base = Path(state_home) if state_home else Path.home() / ".local" / "state"
    return base / "reposync" / "alerts.json"


@contextmanager
def _locked_state():
    """Context manager for thread-safe/process-safe access to alert state."""
    path = _state_path()
    path.parent.mkdir(parents=True, exist_ok=True)

    # We open in a+ to allow reading and writing, ensuring the file exists.
    f = open(path, "a+")
    try:
        fcntl.flock(f, fcntl.LOCK_EX)
        f.seek(0)
        try:
            content = f.read()
            state = json.loads(content) if content else {}
        except (json.JSONDecodeError, OSError) as e:
            click.echo(f"Warning: failed to read reposync alert state: {e}", err=True)
            state = {}

        yield state

        # Write back
        f.seek(0)
        f.truncate()
        f.write(json.dumps(state, sort_keys=True, indent=2))
        f.flush()
        os.fsync(f.fileno())
    finally:
        # flock is automatically released when the file is closed
        f.close()


def _format_duration(seconds):
    seconds = max(0, int(seconds))
    if seconds >= 60 * 60:
        return f"{(seconds + 3599) // 3600}h"
    if seconds >= 60:
        return f"{(seconds + 59) // 60}m"
    return f"{seconds}s"
