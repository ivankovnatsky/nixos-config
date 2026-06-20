"""Shared pending-notification digest store.

Producers (reposync, rebuild, ...) record pending failure notifications here
instead of posting to Discord immediately. A scheduled flush
(`notifications digest-flush`, run once a day at 21:00) posts everything that is
still pending and clears it. Producers clear their own entries as soon as the
underlying condition resolves, so anything that self-heals before the flush is
dropped silently and never reaches Discord.

State layout (a single JSON file, locked with flock):

    {
      "pending": {
        "<key>": {
          "category": "reposync",
          "source": "reposync@host",       # optional label, informational
          "message": "<fully formatted Discord content>",
          "webhook_file": "/path/to/sops/webhook",
          "first_seen": 1700000000.0,
          "last_seen": 1700000300.0
        }
      }
    }

The webhook *file path* (not the URL) is stored so the secret never lands in a
new on-disk location; the flush reads the URL from that file at send time.

`message` is stored already fully formatted (including any
`**[source@host]**` prefix) so the flush can post it verbatim.
"""

from __future__ import annotations

import fcntl
import hashlib
import json
import os
import time
from contextlib import contextmanager
from pathlib import Path

ENV_STATE_FILE = "NOTIFICATIONS_STATE_FILE"

# Discord caps message content at 2000 chars; leave headroom for the digest
# header and joining whitespace.
_DISCORD_LIMIT = 1900


def default_state_path() -> Path:
    """Canonical shared state path, overridable via NOTIFICATIONS_STATE_FILE.

    Always ~/.local/state/notifications/pending.json on every platform so the
    path is identical across macOS and Linux.
    """
    env_path = os.environ.get(ENV_STATE_FILE)
    if env_path:
        return Path(env_path)

    return Path.home() / ".local" / "state" / "notifications" / "pending.json"


def _stable(message: str) -> str:
    # Strip volatile details (after the last " — ") so the same recurring
    # failure collapses to one pending entry regardless of changing specifics.
    return message.rsplit(" — ", 1)[0]


def _key(category: str, message: str) -> str:
    return hashlib.sha256(f"{category}\x00{_stable(message)}".encode("utf-8")).hexdigest()


@contextmanager
def _locked(state_file=None):
    path = Path(state_file) if state_file else default_state_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    f = open(path, "a+")
    try:
        fcntl.flock(f, fcntl.LOCK_EX)
        f.seek(0)
        try:
            content = f.read()
            state = json.loads(content) if content else {}
        except (json.JSONDecodeError, OSError):
            state = {}
        if not isinstance(state, dict):
            state = {}
        yield state
        f.seek(0)
        f.truncate()
        f.write(json.dumps(state, sort_keys=True, indent=2))
        f.flush()
        os.fsync(f.fileno())
    finally:
        f.close()


def record(category, message, webhook_file, *, source=None, dedup_text=None, state_file=None):
    """Upsert a pending notification. Idempotent for a recurring failure.

    `dedup_text` overrides what the dedup key is derived from. Use it when the
    message body carries volatile content (e.g. a rebuild log excerpt) that
    would otherwise spawn a fresh entry per occurrence; pass a stable string so
    repeated occurrences collapse onto one entry (whose message is refreshed).
    """
    now = time.time()
    key = _key(category, dedup_text if dedup_text is not None else message)
    with _locked(state_file) as state:
        pending = state.setdefault("pending", {})
        existing = pending.get(key, {})
        pending[key] = {
            "category": category,
            "source": source,
            "message": message,
            "webhook_file": str(webhook_file) if webhook_file else None,
            "first_seen": existing.get("first_seen", now),
            "last_seen": now,
        }


def clear(category, *, message_prefix=None, state_file=None):
    """Drop pending entries for a category (optionally filtered by message prefix).

    Called by producers when the underlying condition resolves, so the entry
    never reaches the 21:00 flush.
    """
    with _locked(state_file) as state:
        pending = state.get("pending", {})
        to_remove = [
            k
            for k, v in pending.items()
            if v.get("category") == category
            and (message_prefix is None or v.get("message", "").startswith(message_prefix))
        ]
        for k in to_remove:
            del pending[k]


def _pack(items):
    """Combine (key, message) items into chunks no larger than the Discord limit.

    Returns a list of (text, [keys]) so the caller can clear exactly the entries
    whose chunk was posted. A single message longer than the limit is emitted on
    its own (callers are expected to have pre-truncated such payloads, e.g.
    rebuild log excerpts).
    """
    chunks = []
    current_text = ""
    current_keys = []
    for key, msg in items:
        if len(msg) >= _DISCORD_LIMIT:
            if current_text:
                chunks.append((current_text, current_keys))
                current_text, current_keys = "", []
            chunks.append((msg, [key]))
            continue
        candidate = msg if not current_text else f"{current_text}\n\n{msg}"
        if len(candidate) > _DISCORD_LIMIT:
            chunks.append((current_text, current_keys))
            current_text, current_keys = msg, [key]
        else:
            current_text = candidate
            current_keys.append(key)
    if current_text:
        chunks.append((current_text, current_keys))
    return chunks


def _read_webhook(webhook_file):
    if not webhook_file:
        return None
    try:
        url = Path(webhook_file).read_text().strip()
    except OSError:
        return None
    return url if url.startswith("https://") else None


def flush(send_fn, *, state_file=None, log=lambda _msg: None):
    """Post all pending notifications, then clear the ones that were sent.

    `send_fn(webhook_url, content) -> bool` does the actual Discord post.
    Entries whose webhook file is missing/unreadable, or whose send fails, are
    kept so the next flush retries them.
    """
    # Snapshot under lock; do network I/O without holding the lock.
    with _locked(state_file) as state:
        pending = dict(state.get("pending", {}))

    if not pending:
        log("Digest flush: nothing pending.")
        return

    # Group by webhook file so each Discord channel gets its own digest.
    groups = {}
    for key, entry in pending.items():
        groups.setdefault(entry.get("webhook_file"), []).append((key, entry))

    sent_keys = []
    for webhook_file, items in groups.items():
        url = _read_webhook(webhook_file)
        if not url:
            log(f"Digest flush: webhook unreadable ({webhook_file}); keeping {len(items)} entry(s).")
            continue

        # Clear only the entries whose chunk actually posted. Stop at the first
        # failure so we never re-post an already-delivered chunk on the next
        # flush (which would duplicate it). Carry each entry's snapshot
        # last_seen so the pop below can skip entries re-recorded meanwhile.
        keyed = [(k, e.get("message", ""), e.get("last_seen")) for k, e in items]
        for text, chunk in _pack([((k, ls), msg) for k, msg, ls in keyed]):
            if send_fn(url, text):
                sent_keys.extend(chunk)
            else:
                log("Digest flush: Discord post failed; keeping remaining entries for retry.")
                break

    if not sent_keys:
        return

    with _locked(state_file) as state:
        pending = state.get("pending", {})
        cleared = 0
        for key, snapshot_last_seen in sent_keys:
            entry = pending.get(key)
            if entry is None:
                continue
            # A producer may have re-recorded this key (still failing) between
            # the snapshot and now; its last_seen advances. Only drop entries
            # untouched since the snapshot, so a still-failing one survives.
            if entry.get("last_seen") == snapshot_last_seen:
                del pending[key]
                cleared += 1
    log(f"Digest flush: posted and cleared {cleared} entry(s).")
