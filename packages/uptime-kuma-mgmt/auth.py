"""Authentication helpers for uptime-kuma-mgmt."""

import os



def read_secret(env_var: str, default_path: str) -> str | None:
    """Read secret from env var or default file path."""
    if value := os.environ.get(env_var):
        return value

    try:
        return open(os.path.expanduser(default_path)).read().strip()
    except (OSError, IOError):
        return None
