#!/usr/bin/env python3
"""
Nix rebuild tool with two modes:
  rebuild CONFIG_PATH         - single rebuild with notifications (quiet output)
  rebuild watch CONFIG_PATH   - watchman file-watching + optional loop/polling
"""

import json
import re
import sys
import subprocess
import platform
import os
import logging
import tempfile
import time
import threading
import socket
import urllib.request
from collections import deque
from pathlib import Path

import click
import pywatchman


def format_duration(seconds):
    """Format seconds as a human-readable duration (e.g., 180 -> '3m', 90 -> '1m30s')."""
    if seconds < 60:
        return f"{seconds}s"
    minutes, secs = divmod(int(seconds), 60)
    if secs == 0:
        return f"{minutes}m"
    return f"{minutes}m{secs}s"


# Default interval for loop mode in seconds
LOOP_INTERVAL = 180  # 3 minutes

# Debounce delay in seconds - wait this long after last change before rebuilding
DEBOUNCE_DELAY = 20.0

# Configure logging to write to stdout instead of stderr
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout)],
)


# ---------------------------------------------------------------------------
# Watchman helpers
# ---------------------------------------------------------------------------


def load_watchman_ignores(config_path):
    """Load ignore patterns from .rebuild.json."""
    patterns = []
    custom_config = Path(config_path) / ".rebuild.json"
    if custom_config.exists():
        try:
            with open(custom_config, "r") as f:
                config = json.load(f)
                raw_patterns = config.get("ignore_patterns", [])
                patterns.extend([p.rstrip("/") for p in raw_patterns])
        except Exception as e:
            logging.warning(f"Failed to parse .rebuild.json: {e}")
    return patterns


def build_watchman_expression(ignore_patterns):
    """Build watchman expression with exclusions from ignore patterns."""
    expression = ["allof", ["type", "f"]]

    for pattern in ignore_patterns:
        match_opts = {"includedotfiles": True}

        if "*" in pattern:
            expression.append(["not", ["match", pattern, "wholename", match_opts]])
            if not pattern.startswith("**"):
                expression.append(
                    ["not", ["match", f"**/{pattern}", "wholename", match_opts]]
                )
        else:
            expression.append(
                ["not", ["match", f"**/{pattern}/**", "wholename", match_opts]]
            )
            expression.append(
                ["not", ["match", f"{pattern}/**", "wholename", match_opts]]
            )
            expression.append(
                ["not", ["match", f"**/{pattern}", "wholename", match_opts]]
            )
            expression.append(["not", ["match", pattern, "wholename", match_opts]])
            expression.append(["not", ["match", pattern, "basename", match_opts]])

    return expression


def get_machine_dirs(config_path):
    """Return set of machine directory names under machines/."""
    machines_dir = Path(config_path) / "machines"
    if machines_dir.is_dir():
        return {d.name for d in machines_dir.iterdir() if d.is_dir()}
    return set()


def filter_files_for_machine(files, other_machines):
    """Filter out files belonging to other machines."""
    if not other_machines:
        return files

    relevant = []
    skipped = []
    for f in files:
        parts = Path(f).parts
        if len(parts) >= 2 and parts[0] == "machines" and parts[1] in other_machines:
            skipped.append(f)
        else:
            relevant.append(f)

    if skipped:
        logging.info(f"Filtered out {len(skipped)} file(s) belonging to other machines")
        for f in skipped[:5]:
            logging.debug(f"  skipped: {f}")
        if len(skipped) > 5:
            logging.debug(f"  ... and {len(skipped) - 5} more")

    return relevant


# ---------------------------------------------------------------------------
# Shared infrastructure
# ---------------------------------------------------------------------------


def reset_terminal():
    """Reset terminal settings to sane defaults."""
    try:
        if sys.stdout.isatty():
            subprocess.run(
                ["stty", "sane"],
                stdin=sys.stdout,
                check=False,
                capture_output=True,
            )
    except Exception:
        pass


def detect_rebuild_command():
    """Detect the appropriate rebuild command based on platform."""
    system = platform.system()
    args = "switch --impure -L --flake ."

    is_root = os.geteuid() == 0
    sudo_prefix = "" if is_root else "sudo -E "

    if system == "Darwin":
        return f"{sudo_prefix}/run/current-system/sw/bin/darwin-rebuild {args}"
    elif system == "Linux":
        return f"{sudo_prefix}/run/current-system/sw/bin/nixos-rebuild {args}"
    else:
        raise RuntimeError(f"Unsupported platform: {system}")


DEFAULT_DISCORD_WEBHOOK_FILE = (
    Path.home() / ".config" / "sops-nix" / "secrets" / "discord-webhook-rebuild"
)


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

    payload = json.dumps({"content": body}).encode()
    req = urllib.request.Request(
        webhook_url,
        data=payload,
        # Cloudflare blocks Python's default urllib User-Agent with HTTP 403.
        headers={
            "Content-Type": "application/json",
            "User-Agent": "rebuild/1.0",
        },
    )
    try:
        urllib.request.urlopen(req, timeout=10)
    except Exception as e:
        logging.warning(f"Discord notification failed: {e}")


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


def run_rebuild(config_path, command, quiet=False):
    """Run the rebuild command. Returns (return_code, actually_ran).

    When quiet=True, stream output to a temp file instead of the terminal.
    On failure, send context around the last error marker so the user can debug.
    """
    if not acquire_lock():
        logging.info("Skipping rebuild - another rebuild is in progress")
        return (0, False)

    try:
        logging.info(f"Running: {command}")
        env = os.environ.copy()
        env["NIXPKGS_ALLOW_UNFREE"] = "1"

        if quiet:
            fd, log_name = tempfile.mkstemp(prefix="rebuild-", suffix=".log")
            os.close(fd)
            log_path = Path(log_name)
            result = None
            try:
                with open(log_path, "w") as log_file:
                    result = subprocess.run(
                        command,
                        shell=True,
                        cwd=config_path,
                        env=env,
                        stdout=log_file,
                        stderr=subprocess.STDOUT,
                    )
                reset_terminal()
                if result.returncode == 0:
                    logging.info("Rebuild successful")
                else:
                    logging.error(f"Rebuild failed with exit code {result.returncode}")
                    context = None
                    try:
                        lines = read_log_tail(log_path)
                        context = extract_error_context(lines)
                        logging.error(f"Log excerpt (full log: {log_path}):")
                        for line in context:
                            logging.error(f"  {line}")
                    except Exception as e:
                        logging.warning(f"Failed to extract log context: {e}")
                    send_failure_notification(
                        exit_code=result.returncode, log_excerpt=context
                    )
            finally:
                if result is None or result.returncode == 0:
                    log_path.unlink(missing_ok=True)
        else:
            result = subprocess.run(
                command, shell=True, cwd=config_path, env=env, stderr=subprocess.STDOUT
            )
            reset_terminal()
            if result.returncode == 0:
                logging.info("Rebuild successful")
            else:
                logging.error(f"Rebuild failed with exit code {result.returncode}")
                send_failure_notification(exit_code=result.returncode)

        return (result.returncode, True)
    finally:
        release_lock()


def refresh_sudo():
    """Refresh sudo credentials so rebuilds don't prompt for password."""
    try:
        result = subprocess.run(
            ["sudo", "-v"],
            check=False,
            capture_output=True,
        )
        if result.returncode != 0:
            logging.warning("Failed to refresh sudo credentials")
            return False
        return True
    except Exception as e:
        logging.warning(f"Failed to refresh sudo credentials: {e}")
        return False


# ---------------------------------------------------------------------------
# Simple mode: single rebuild with notifications, quiet output
# ---------------------------------------------------------------------------


def cmd_simple(config_path, command):
    """Run a single rebuild with notifications and suppressed output."""
    config_path_obj = Path(config_path)

    reset_terminal()

    if platform.system() == "Darwin":
        if not config_path_obj.exists():
            logging.info(f"Waiting for {config_path} to be available...")
            subprocess.run(["/bin/wait4path", str(config_path)], check=True)
            logging.info(f"{config_path} is now available!")

    if not config_path_obj.exists():
        logging.error(f"Config path does not exist: {config_path}")
        sys.exit(1)

    os.chdir(config_path)

    # git add -A before rebuild (same as Makefile addall)
    subprocess.run(["git", "add", "-A"], cwd=config_path, check=False)

    if not command:
        command = detect_rebuild_command()
    logging.info(f"Rebuild command: {command}")

    # Refresh sudo before quiet mode so the password prompt is visible
    if "sudo" in command:
        refresh_sudo()

    returncode, _ = run_rebuild(config_path, command, quiet=True)
    sys.exit(returncode)


# ---------------------------------------------------------------------------
# Watch mode: watchman file-watching + optional loop/polling
# ---------------------------------------------------------------------------


def setup_watchman_subscription(client, config_path, ignore_patterns):
    """Set up watchman watch and subscription."""
    watch_result = client.query("watch-project", config_path)
    if "warning" in watch_result:
        logging.warning(f"Watchman warning: {watch_result['warning']}")

    root = watch_result["watch"]
    relative_path = watch_result.get("relative_path", "")

    logging.info(f"Watchman watching: {root}")

    query = {
        "expression": build_watchman_expression(ignore_patterns),
        "fields": ["name"],
    }

    if relative_path:
        query["relative_root"] = relative_path

    sub_name = "rebuild"
    client.query("subscribe", root, sub_name, query)

    logging.info("Watching for changes...")
    return root, sub_name


def cmd_watch(config_path, command, loop, no_watch, interval):
    """Watch for changes and rebuild."""
    config_path_obj = Path(config_path)
    watch = not no_watch

    reset_terminal()

    if check_existing_instance():
        sys.exit(0)

    write_instance_file()
    cleanup_stale_lock()

    if platform.system() == "Darwin":
        if not config_path_obj.exists():
            logging.info(f"Waiting for {config_path} to be available...")
            subprocess.run(["/bin/wait4path", str(config_path)], check=True)
            logging.info(f"{config_path} is now available!")

    if not config_path_obj.exists():
        logging.error(f"Config path does not exist: {config_path}")
        sys.exit(1)

    os.chdir(config_path)

    if command:
        logging.info(f"Rebuild command: {command}")
    else:
        command = detect_rebuild_command()
        logging.info(f"Auto-detected rebuild command: {command}")

    hostname = socket.gethostname().removesuffix(".local")
    logging.info(f"Current machine: {hostname} (filtering changes for other machines)")

    machine_dirs = get_machine_dirs(config_path)
    if machine_dirs and hostname not in machine_dirs:
        logging.warning(
            f"Hostname '{hostname}' not found in machines/ directories: {machine_dirs}. "
            "Machine filtering may not work correctly."
        )
    other_machines = machine_dirs - {hostname}

    ignore_patterns = load_watchman_ignores(config_path)
    logging.info(f"Loaded ignore patterns from .rebuild.json: {ignore_patterns}")

    RECONNECT_DELAY = 5
    MAX_RECONNECT_ATTEMPTS = 10

    debounce_timer = None
    pending_files = []
    timer_lock = threading.Lock()
    rebuild_lock = threading.Lock()
    loop_stop_event = threading.Event()

    def loop_timer_thread():
        logging.info(f"Loop timer started (interval: {format_duration(interval)})")
        while not loop_stop_event.wait(interval):
            logging.info("Loop timer fired, triggering periodic rebuild")
            if not refresh_sudo():
                logging.warning("Failed to refresh sudo, attempting rebuild anyway")
            with timer_lock:
                nonlocal debounce_timer
                if debounce_timer is not None:
                    debounce_timer.cancel()
                    debounce_timer = None
            trigger_rebuild(loop_triggered=True)

    def trigger_rebuild(loop_triggered=False):
        nonlocal pending_files, debounce_timer
        with timer_lock:
            if pending_files:
                files_to_rebuild = list(pending_files)
                if loop_triggered and files_to_rebuild:
                    logging.info("=" * 60)
                    logging.info(
                        f"Loop timer + {len(files_to_rebuild)} file change(s):"
                    )
                    for f in files_to_rebuild[:10]:
                        logging.info(f"  - {f}")
                    if len(files_to_rebuild) > 10:
                        logging.info(f"  ... and {len(files_to_rebuild) - 10} more")
                    logging.info("=" * 60)
                elif not loop_triggered:
                    logging.info("=" * 60)
                    logging.info(
                        f"Rebuilding after {len(files_to_rebuild)} file change(s):"
                    )
                    for f in files_to_rebuild[:10]:
                        logging.info(f"  - {f}")
                    if len(files_to_rebuild) > 10:
                        logging.info(f"  ... and {len(files_to_rebuild) - 10} more")
                    logging.info("=" * 60)
                pending_files = []
            else:
                files_to_rebuild = []

            if loop_triggered and not files_to_rebuild:
                logging.info("=" * 60)
                logging.info("Periodic loop rebuild (no file changes)")
                logging.info("=" * 60)

        if files_to_rebuild:
            files_to_rebuild = filter_files_for_machine(
                files_to_rebuild, other_machines
            )

        if not files_to_rebuild and not loop_triggered:
            logging.info("All changed files belong to other machines, skipping rebuild")
            return

        if files_to_rebuild or loop_triggered:
            # Stage all files so nix flake sees new/changed files
            subprocess.run(["git", "add", "-A"], cwd=config_path, check=False)
            with rebuild_lock:
                _, actually_ran = run_rebuild(config_path, command)
            if not actually_ran:
                with timer_lock:
                    for f in files_to_rebuild:
                        if f not in pending_files:
                            pending_files.append(f)
                    logging.info(
                        f"Re-queued {len(files_to_rebuild)} file(s), will rebuild after current rebuild finishes"
                    )
            else:
                with timer_lock:
                    if pending_files:
                        logging.info(
                            f"{len(pending_files)} file(s) changed during rebuild, scheduling follow-up rebuild in {format_duration(DEBOUNCE_DELAY)}"
                        )
                        debounce_timer = threading.Timer(
                            DEBOUNCE_DELAY, trigger_rebuild
                        )
                        debounce_timer.start()

    client = None
    reconnect_attempts = 0

    # Always run an initial rebuild on startup
    logging.info("Running initial rebuild on startup")
    subprocess.run(["git", "add", "-A"], cwd=config_path, check=False)
    if "sudo" in command:
        refresh_sudo()
    with rebuild_lock:
        run_rebuild(config_path, command)

    if loop:
        if not refresh_sudo():
            logging.warning("Failed initial sudo refresh")
        loop_thread = threading.Thread(target=loop_timer_thread, daemon=True)
        loop_thread.start()

    try:
        if watch:
            while True:
                if client is None:
                    try:
                        client = pywatchman.client()
                        root, sub_name = setup_watchman_subscription(
                            client, config_path, ignore_patterns
                        )
                        reconnect_attempts = 0
                    except (pywatchman.WatchmanError, Exception) as e:
                        reconnect_attempts += 1
                        if reconnect_attempts >= MAX_RECONNECT_ATTEMPTS:
                            logging.error(
                                f"Failed to connect to watchman after {MAX_RECONNECT_ATTEMPTS} attempts, exiting"
                            )
                            sys.exit(1)
                        logging.error(f"Failed to connect to watchman: {e}")
                        logging.info(
                            f"Retrying in {format_duration(RECONNECT_DELAY)} (attempt {reconnect_attempts}/{MAX_RECONNECT_ATTEMPTS})..."
                        )
                        time.sleep(RECONNECT_DELAY)
                        continue

                try:
                    result = client.receive()

                    if "subscription" in result and result["subscription"] == sub_name:
                        if result.get("is_fresh_instance"):
                            logging.info("Fresh watchman instance")
                            continue

                        files = result.get("files", [])
                        if files:
                            with timer_lock:
                                for f in files:
                                    fname = (
                                        f
                                        if isinstance(f, str)
                                        else f.get("name", str(f))
                                    )
                                    if fname not in pending_files:
                                        pending_files.append(fname)

                                if debounce_timer is not None:
                                    debounce_timer.cancel()

                                logging.info(
                                    f"Change detected, waiting {format_duration(DEBOUNCE_DELAY)} for more changes..."
                                )
                                debounce_timer = threading.Timer(
                                    DEBOUNCE_DELAY, trigger_rebuild
                                )
                                debounce_timer.start()

                except pywatchman.SocketTimeout:
                    continue
                except pywatchman.WatchmanError as e:
                    logging.warning(f"Watchman error: {e}")
                    logging.info(
                        f"Reconnecting in {format_duration(RECONNECT_DELAY)}..."
                    )
                    try:
                        client.close()
                    except Exception:
                        pass
                    client = None
                    time.sleep(RECONNECT_DELAY)
        else:
            logging.info("File watching disabled, running in loop-only mode")
            loop_stop_event.wait()

    except KeyboardInterrupt:
        logging.info("Received interrupt, stopping...")
    finally:
        loop_stop_event.set()
        if debounce_timer is not None:
            debounce_timer.cancel()
        if client is not None:
            try:
                client.close()
            except Exception:
                pass
        cleanup_instance_file()


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------


class DefaultToSimple(click.Group):
    """If the first arg isn't a known subcommand, treat it as 'simple <args>'."""

    def parse_args(self, ctx, args):
        if args and args[0] not in self.commands and not args[0].startswith("-"):
            args = ["simple"] + args
        return super().parse_args(ctx, args)


@click.group(cls=DefaultToSimple)
def cli():
    """Nix rebuild tool with simple and watch modes."""


@cli.command()
@click.argument("config_path")
@click.argument("command", required=False, default=None)
def simple(config_path, command):
    """Single rebuild with notifications (quiet output)."""
    cmd_simple(config_path, command)


@cli.command()
@click.argument("config_path")
@click.argument("command", required=False, default=None)
@click.option(
    "--loop",
    is_flag=True,
    help="Also rebuild periodically every INTERVAL seconds (with sudo refresh)",
)
@click.option(
    "--no-watch",
    is_flag=True,
    help="Disable file watching (use with --loop for timer-only mode)",
)
@click.option(
    "--interval",
    type=int,
    default=LOOP_INTERVAL,
    help=f"Interval in seconds between periodic rebuilds when --loop is used (default: {LOOP_INTERVAL})",
)
def watch(config_path, command, loop, no_watch, interval):
    """Watch for file changes and rebuild automatically."""
    if interval != LOOP_INTERVAL and not loop:
        raise click.UsageError("--interval requires --loop")
    if no_watch and not loop:
        raise click.UsageError(
            "--no-watch requires --loop (nothing to do without watching or looping)"
        )
    cmd_watch(config_path, command, loop, no_watch, interval)


if __name__ == "__main__":
    cli(prog_name="rebuild")
