"""File-based cache for notes CLI."""

import hashlib
import json
import os
import shutil
import time

CACHE_DIR = os.path.join(
    os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "notes-cli"
)
CACHE_TTL = 300  # 5 minutes


def _cache_path(key):
    safe = hashlib.md5(key.encode()).hexdigest()
    return os.path.join(CACHE_DIR, f"{safe}.json")


def cache_get(key):
    """Return cached value or None if expired/missing."""
    path = _cache_path(key)
    try:
        with open(path) as f:
            data = json.load(f)
        if time.time() - data["ts"] < CACHE_TTL:
            return data["val"]
    except (OSError, json.JSONDecodeError, KeyError):
        pass
    return None


def cache_set(key, val):
    """Store value in cache."""
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(_cache_path(key), "w") as f:
        json.dump({"ts": time.time(), "val": val}, f)


def cache_invalidate():
    """Clear all cached data."""
    if os.path.isdir(CACHE_DIR):
        shutil.rmtree(CACHE_DIR, ignore_errors=True)
