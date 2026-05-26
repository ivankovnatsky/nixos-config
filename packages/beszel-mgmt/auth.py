"""Secret-reading helpers for beszel-mgmt."""

import os


def read_secret_file(path: str) -> str | None:
    """Read and strip a secret file's contents, or None if missing.

    Distinguishes FileNotFoundError (silent None) from other OSError
    (re-raise) so a permissions error isn't masked as "not configured".
    """
    try:
        return open(os.path.expanduser(path)).read().strip()
    except FileNotFoundError:
        return None
