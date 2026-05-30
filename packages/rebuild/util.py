"""Shared utilities for rebuild."""


def format_duration(seconds):
    """Format seconds as a human-readable duration (e.g., 180 -> '3m', 90 -> '1m30s')."""
    if seconds < 60:
        return f"{seconds}s"
    minutes, secs = divmod(int(seconds), 60)
    if secs == 0:
        return f"{minutes}m"
    return f"{minutes}m{secs}s"


# Default interval between periodic rebuilds in seconds
LOOP_INTERVAL = 180  # 3 minutes

# Debounce delay in seconds - wait this long after last change before rebuilding
DEBOUNCE_DELAY = 20.0
