"""Turnoff: Set volume and shutdown system (macOS + Linux)."""

from __future__ import annotations

import subprocess
import sys

import click

from common import TURNOFF_VOLUME_SET, is_linux, is_macos
from volume import volume_set

_PERMISSION_MARKERS = (
    "permission denied",
    "must be root",
    "not permitted",
    "operation not permitted",
    "access denied",
)


def _linux_shutdown() -> None:
    try:
        result = subprocess.run(
            ["systemctl", "poweroff"],
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
        default=TURNOFF_VOLUME_SET,
        help=f"Volume level before shutdown (default: {TURNOFF_VOLUME_SET}%)",
    )
    def turnoff(vol):
        """Set volume and shutdown system (macOS + Linux)"""
        if not is_macos() and not is_linux():
            print("Turnoff only available on macOS and Linux", file=sys.stderr)
            sys.exit(1)

        # Set volume to specified level before shutdown
        if volume_set(vol):
            print(f"Volume set to {vol}%")
        else:
            print("Warning: Could not set volume", file=sys.stderr)

        # Shutdown the system
        print("Shutting down...")
        if is_linux():
            _linux_shutdown()
        elif is_macos():
            subprocess.run(
                ["osascript", "-e", 'tell app "System Events" to shut down'],
                check=True,
            )
