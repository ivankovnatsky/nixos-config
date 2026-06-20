"""Alerting via the shared notification digest.

Failures are not posted to Discord immediately. They are recorded in the shared
digest store (see packages/discord/digest.py) and posted in a batch by the
daily 21:00 `notifications digest-flush`. When a repo syncs successfully its
pending entry is cleared, so a failure that self-heals before 21:00 never
reaches Discord.
"""

import platform

import click

import digest

CATEGORY = "reposync"

_webhook_file = None
_digest_state_file = None
_hostname = platform.node()


def configure_alerts(repeat_seconds=None, state_file=None, webhook_file=None):
    # repeat_seconds/state_file are retained for config compatibility but are no
    # longer used: deferral to the 21:00 digest replaces immediate rate-limited
    # sending.
    global _webhook_file, _digest_state_file
    if webhook_file:
        _webhook_file = webhook_file
    if state_file:
        _digest_state_file = state_file


def _content(message):
    return f"**[{CATEGORY}@{_hostname}]** {message}"


def alert(webhook_url, message):
    click.echo(f"ALERT: {message}", err=True)
    if not _webhook_file:
        click.echo(
            "No Discord webhook file configured; alert not recorded for digest.",
            err=True,
        )
        return

    digest.record(
        CATEGORY,
        _content(message),
        _webhook_file,
        source=f"{CATEGORY}@{_hostname}",
        state_file=_digest_state_file,
    )
    click.echo("Recorded for 21:00 digest.", err=True)


def clear_alerts_for_repo(repo_name):
    """Drop the pending digest entry for a repository that synced successfully.

    Called on every successful sync, so a transient failure that recovers before
    the 21:00 flush is silently dropped and never alerted.
    """
    prefix = _content(f"`{repo_name}`:")
    digest.clear(CATEGORY, message_prefix=prefix, state_file=_digest_state_file)
