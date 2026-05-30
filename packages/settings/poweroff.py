"""Poweroff: Set volume and shutdown system (macOS + Linux)."""

from __future__ import annotations

import subprocess
import sys
import time
from datetime import date
from pathlib import Path

import click

from common import POWEROFF_VOLUME_SET, is_linux, is_macos
from volume import volume_set

ICLOUD_SYNC_DELAY = 5  # seconds to wait for iCloud sync (file is < 1KB)


def poweroff_log_battery() -> None:
    """Log battery status to iCloud stats directory (macOS laptops only)."""
    if not is_macos():
        return

    import socket

    try:
        result = subprocess.run(
            ["pmset", "-g", "batt"],
            capture_output=True,
            text=True,
        )

        if "InternalBattery" not in result.stdout:
            return

        hostname = socket.gethostname()
        today = date.today().isoformat()
        stats_dir = (
            Path.home()
            / "Library/Mobile Documents/com~apple~CloudDocs/Data/Stats"
            / hostname
            / today
        )
        stats_dir.mkdir(parents=True, exist_ok=True)

        battery_file = stats_dir / "battery.txt"
        battery_file.write_text(result.stdout)
        print(f"Battery status logged to {battery_file}")

        # Wait for iCloud to sync (file is tiny, should be instant)
        print(f"Waiting {ICLOUD_SYNC_DELAY}s for iCloud sync...")
        time.sleep(ICLOUD_SYNC_DELAY)
    except Exception as e:
        print(f"Warning: Could not log battery status: {e}", file=sys.stderr)


_PERMISSION_MARKERS = ("permission denied", "must be root", "not permitted", "operation not permitted")


def _linux_shutdown() -> None:
    try:
        result = subprocess.run(
            ["shutdown", "-h", "now"],
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        _sudo_shutdown()
        return

    if result.returncode == 0:
        return

    if any(m in result.stderr.lower() for m in _PERMISSION_MARKERS):
        _sudo_shutdown()
    else:
        print(result.stderr, file=sys.stderr, end="")
        sys.exit(result.returncode)


def _sudo_shutdown() -> None:
    try:
        subprocess.run(["sudo", "shutdown", "-h", "now"], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error: sudo shutdown failed (exit {e.returncode})", file=sys.stderr)
        sys.exit(e.returncode)


def register(cli):
    @cli.command()
    @click.option(
        "--volume",
        "vol",
        type=click.IntRange(min=0, max=100),
        default=POWEROFF_VOLUME_SET,
        help=f"Volume level before shutdown (default: {POWEROFF_VOLUME_SET}%)",
    )
    def poweroff(vol):
        """Set volume and shutdown system (macOS + Linux)"""
        if not is_macos() and not is_linux():
            print("Poweroff only available on macOS and Linux", file=sys.stderr)
            sys.exit(1)

        # Log battery status before shutdown (macOS only)
        poweroff_log_battery()

        # Set volume to specified level before shutdown
        if volume_set(vol):
            print(f"Volume set to {vol}%")
        else:
            print("Warning: Could not set volume", file=sys.stderr)

        # Shutdown the system
        print("Shutting down...")
        if is_linux():
            _linux_shutdown()
        else:
            subprocess.run(["sudo", "shutdown", "-h", "now"], check=True)
