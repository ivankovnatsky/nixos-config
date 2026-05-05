"""Discord failure notifications and nix log error extraction."""

import logging
import platform
import re
import socket
from collections import deque
from pathlib import Path

from discord import send_discord as _send_discord


DEFAULT_DISCORD_WEBHOOK_FILE = (
    Path.home() / ".config" / "sops-nix" / "secrets" / "discord-webhook-rebuild"
)

# Lines to include before/after the last nix `error:` marker when extracting
# failure context. Both windows are generous because nix's "builder for X
# failed; last 25 log lines:" block can sit on either side of the final
# `error:` line depending on whether the last marker is the original failure
# or a downstream "N dependencies of derivation failed" cascade summary.
ERROR_CONTEXT_BEFORE = 30
ERROR_CONTEXT_AFTER = 30

# Fallback tail size when no error marker is found.
FALLBACK_TAIL_LINES = 30

# Cap on lines kept in memory while reading the log. Nix builds with `-L` can
# produce very large logs; this bounds memory while still leaving plenty of
# room for context extraction.
MAX_LOG_LINES = 2000

# Match nix's actual error lines (anchored to start, optional whitespace prefix
# for indented continuation), not stray substrings in test output or paths.
ERROR_LINE_RE = re.compile(r"^\s*error:")


def read_log_tail(log_path, max_lines=MAX_LOG_LINES):
    """Read up to the last `max_lines` of a log file without slurping it whole.

    Uses `errors="replace"` because nix build logs routinely contain non-UTF-8
    bytes (terminal escape sequences, locale-mismatched compiler output) and a
    decode error here would suppress the entire failure context.
    """
    with open(log_path, errors="replace") as f:
        return [line.rstrip("\n") for line in deque(f, maxlen=max_lines)]


def extract_error_context(
    lines, before=ERROR_CONTEXT_BEFORE, after=ERROR_CONTEXT_AFTER
):
    """Return lines around the last nix `error:` marker.

    Scans from the end because nix's actionable root cause is typically the
    final `error:` line — earlier ones are usually "builder for X failed"
    cascades or unrelated `error:` substrings from passing test output (`-L`).
    Falls back to the last `FALLBACK_TAIL_LINES` lines if no marker is found.
    """
    error_idx = next(
        (i for i in range(len(lines) - 1, -1, -1) if ERROR_LINE_RE.match(lines[i])),
        None,
    )
    if error_idx is None:
        return lines[-FALLBACK_TAIL_LINES:]
    start = max(0, error_idx - before)
    end = min(len(lines), error_idx + after + 1)
    return lines[start:end]


def send_failure_notification(webhook_file=None, exit_code=None, log_excerpt=None):
    """Post a rebuild failure to Discord via webhook.

    Reads the webhook URL from `webhook_file` (defaults to the sops-nix
    rendered path ~/.config/sops-nix/secrets/discord-webhook-rebuild).
    Silently skips if the file is missing or unreadable — never fails
    the rebuild.
    """
    path = Path(webhook_file) if webhook_file else DEFAULT_DISCORD_WEBHOOK_FILE
    if not path.exists():
        logging.debug(
            f"Discord webhook file not present at {path}; skipping notification"
        )
        return

    try:
        webhook_url = path.read_text().strip()
    except Exception as e:
        logging.warning(f"Cannot read Discord webhook file {path}: {e}")
        return

    if not webhook_url.startswith("https://"):
        logging.debug(
            f"Discord webhook URL in {path} is not https; skipping notification"
        )
        return

    hostname = socket.gethostname().removesuffix(".local")
    system = platform.system()
    parts = [f"**[rebuild@{hostname}]** {system} rebuild failed"]
    if exit_code is not None:
        parts.append(f"exit code {exit_code}")
    header = " — ".join(parts)

    body = header
    if log_excerpt:
        # Discord caps content at 2000 chars; reserve room for the header + fences.
        # Trim whole lines from whichever end is farther from the `error:` marker
        # so the root cause survives. (When the last error is a "N dependencies
        # failed" cascade summary, the actionable builder log sits in the
        # *before* half — front-only trimming would discard it.)
        budget = 2000 - len(header) - len("\n```\n\n```")
        lines = list(log_excerpt)
        marker_idx = next(
            (i for i in range(len(lines) - 1, -1, -1) if ERROR_LINE_RE.match(lines[i])),
            len(lines) - 1,
        )
        snippet = "\n".join(lines)
        while len(snippet) > budget and len(lines) > 1:
            tail_pad = len(lines) - 1 - marker_idx
            head_pad = marker_idx
            if tail_pad >= head_pad and tail_pad > 0:
                lines.pop()
            elif head_pad > 0:
                lines.pop(0)
                marker_idx -= 1
            else:
                break
            snippet = "\n".join(lines)
        if len(snippet) > budget:
            snippet = snippet[-budget:]
        body = f"{header}\n```\n{snippet}\n```"

    _send_discord(webhook_url, body, user_agent="rebuild/1.0")
