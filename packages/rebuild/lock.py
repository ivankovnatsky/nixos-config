"""PID/instance lock files for rebuild."""

import logging
import os
import time
from pathlib import Path

from util import format_duration


LOCK_FILE = Path("/tmp/nix-rebuild.lock")
INSTANCE_FILE = Path("/tmp/nix-rebuild.instance")

INSTANCE_RETRY_DELAY = 5
INSTANCE_MAX_RETRIES = 60

# Magic token written alongside PID to identify our files reliably.
# Process-name matching is unreliable because the nix store path
# (e.g. /nix/store/...-main.py) doesn't contain a recognisable name.
INSTANCE_MAGIC = "nix-rebuild-tool"

# PID files older than this are considered stale regardless of PID liveness,
# to guard against PID reuse after a crash.
PID_FILE_MAX_AGE = 24 * 3600  # 24 hours


def _read_pid_file(path):
    """Read a PID file written by this tool. Returns (pid, is_ours) or raises."""
    text = path.read_text().strip()
    parts = text.split("\n", 1)
    pid = int(parts[0])
    is_ours = len(parts) > 1 and parts[1].strip() == INSTANCE_MAGIC
    return pid, is_ours


def _write_pid_file(path):
    """Write current PID + magic token to a file."""
    path.write_text(f"{os.getpid()}\n{INSTANCE_MAGIC}\n")


def is_pid_alive(pid):
    """Check if a PID is still alive."""
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True  # alive but owned by another user


def _is_pid_file_live(path):
    """Check if a PID file written by this tool references a live process.

    Returns (True, pid) if the file has our magic token, PID is alive,
    and the file is not too old (guards against PID reuse after crash).
    Returns (False, pid_or_none) if the file is stale or not ours.
    """
    if not path.exists():
        return False, None
    try:
        pid, is_ours = _read_pid_file(path)
    except (ValueError, FileNotFoundError, PermissionError):
        return False, None
    if not is_ours:
        return False, pid
    # Guard against PID reuse: if the file is very old, a different
    # process likely reused the PID after we crashed without cleanup.
    try:
        age = time.time() - path.stat().st_mtime
        if age > PID_FILE_MAX_AGE:
            logging.info(
                f"PID file {path} is {format_duration(int(age))} old, treating as stale"
            )
            return False, pid
    except OSError:
        pass
    return is_pid_alive(pid), pid


def _remove_stale(path, label="file"):
    """Try to remove a stale PID file, log result."""
    try:
        path.unlink(missing_ok=True)
        logging.info(f"Removed stale {label}: {path}")
    except PermissionError:
        logging.warning(f"Cannot remove stale {label} (permission denied)")


def check_existing_instance():
    """Check if another instance is already running. Retries until it exits or timeout."""
    retries = 0
    while INSTANCE_FILE.exists():
        alive, pid = _is_pid_file_live(INSTANCE_FILE)
        if not alive:
            _remove_stale(INSTANCE_FILE, "instance file")
            break
        retries += 1
        if retries >= INSTANCE_MAX_RETRIES:
            logging.error(
                f"Another instance (PID {pid}) still running after {INSTANCE_MAX_RETRIES} retries, exiting"
            )
            return True
        logging.info(
            f"Another instance is running (PID {pid}), waiting {format_duration(INSTANCE_RETRY_DELAY)} (retry {retries}/{INSTANCE_MAX_RETRIES})..."
        )
        time.sleep(INSTANCE_RETRY_DELAY)
    return False


def write_instance_file():
    """Write current PID to instance file."""
    _write_pid_file(INSTANCE_FILE)
    logging.info(f"Created instance file: {INSTANCE_FILE} (PID {os.getpid()})")


def cleanup_instance_file():
    """Remove instance file on exit."""
    if INSTANCE_FILE.exists():
        INSTANCE_FILE.unlink(missing_ok=True)
        logging.info(f"Removed instance file: {INSTANCE_FILE}")


def cleanup_stale_lock():
    """Remove stale lock file from previous run."""
    alive, pid = _is_pid_file_live(LOCK_FILE)
    if alive:
        logging.info(f"Lock file held by running rebuild (PID {pid}), not removing")
        return
    if LOCK_FILE.exists():
        _remove_stale(LOCK_FILE, "lock file")


def acquire_lock():
    """Acquire rebuild lock. Returns True if acquired, False if already locked."""
    if LOCK_FILE.exists():
        alive, pid = _is_pid_file_live(LOCK_FILE)
        if alive:
            logging.info(
                f"Lock file exists, rebuild already in progress (PID {pid}): {LOCK_FILE}"
            )
            return False
        _remove_stale(LOCK_FILE, "lock file")
        if LOCK_FILE.exists():
            return False  # couldn't remove

    _write_pid_file(LOCK_FILE)
    logging.info(f"Acquired rebuild lock (PID {os.getpid()}): {LOCK_FILE}")
    return True


def release_lock():
    """Release rebuild lock."""
    if LOCK_FILE.exists():
        try:
            LOCK_FILE.unlink()
            logging.info(f"Released rebuild lock: {LOCK_FILE}")
        except FileNotFoundError:
            logging.info("Lock file already removed")
        except PermissionError:
            logging.warning("Cannot release lock file (permission denied)")
