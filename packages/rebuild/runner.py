"""Single rebuild execution: detection, run, sudo refresh, terminal reset."""

import logging
import os
import platform
import subprocess
import sys
import tempfile
from pathlib import Path

from lock import acquire_lock, release_lock
from notify import (
    extract_error_context,
    read_log_tail,
    send_failure_notification,
)


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
