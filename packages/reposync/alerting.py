"""Alerting via Discord webhooks."""

import hashlib
import json
import os
import sys
import time
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
        _record_sent(key)


def clear_alert_state():
    try:
        _state_path().unlink()
    except FileNotFoundError:
        return
    except OSError as e:
        click.echo(f"Warning: failed to clear reposync alert state: {e}", err=True)


def _should_send(message):
    if _repeat_seconds <= 0:
        return True, 0, None

    now = time.time()
    key = _alert_key(message)
    last_sent = _load_state().get(key)
    if last_sent is None:
        return True, 0, key

    elapsed = now - last_sent
    if elapsed >= _repeat_seconds:
        return True, 0, key

    return False, _repeat_seconds - elapsed, key


def _record_sent(key):
    if key is None:
        return

    state = _load_state()
    state[key] = time.time()
    _save_state(state)


def _alert_key(message):
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


def _load_state():
    try:
        data = json.loads(_state_path().read_text())
    except FileNotFoundError:
        return {}
    except (json.JSONDecodeError, OSError) as e:
        click.echo(f"Warning: failed to read reposync alert state: {e}", err=True)
        return {}

    alerts = data.get("alerts", {}) if isinstance(data, dict) else {}
    return {
        key: float(value)
        for key, value in alerts.items()
        if isinstance(key, str) and isinstance(value, (int, float))
    }


def _save_state(alerts):
    path = _state_path()
    payload = json.dumps({"alerts": alerts}, sort_keys=True)

    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp_path = path.with_name(f".{path.name}.tmp")
        tmp_path.write_text(payload)
        os.replace(tmp_path, path)
    except OSError as e:
        click.echo(f"Warning: failed to write reposync alert state: {e}", err=True)


def _format_duration(seconds):
    seconds = max(0, int(seconds))
    if seconds >= 60 * 60:
        return f"{(seconds + 3599) // 3600}h"
    if seconds >= 60:
        return f"{(seconds + 59) // 60}m"
    return f"{seconds}s"
