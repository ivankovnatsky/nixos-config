"""Volume: Get/set system volume (macOS + Linux)."""

from __future__ import annotations

import re
import subprocess
import sys

import click

from common import is_linux, is_macos


def volume_get_macos() -> float | None:
    """Get current volume percentage on macOS using osascript."""
    try:
        result = subprocess.run(
            ["osascript", "-e", "output volume of (get volume settings)"],
            capture_output=True,
            text=True,
            check=True,
        )
        return float(result.stdout.strip())
    except (subprocess.CalledProcessError, FileNotFoundError, ValueError):
        return None


def volume_set_macos(percent: float) -> bool:
    """Set volume percentage on macOS using osascript."""
    try:
        # macOS volume is 0-100
        volume = int(round(percent))
        subprocess.run(
            ["osascript", "-e", f"set volume output volume {volume}"],
            check=True,
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error setting volume: {e}", file=sys.stderr)
        return False


def volume_get_linux() -> float | None:
    """Get current volume percentage on Linux using pactl."""
    try:
        result = subprocess.run(
            ["pactl", "get-sink-volume", "@DEFAULT_SINK@"],
            capture_output=True,
            text=True,
            check=True,
        )
        # Output format: "Volume: front-left: 65536 / 100% / 0.00 dB, ..."
        match = re.search(r"(\d+)%", result.stdout)
        if match:
            return float(match.group(1))
        return None
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def volume_set_linux(percent: float) -> bool:
    """Set volume percentage on Linux using pactl."""
    try:
        subprocess.run(
            ["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{percent:.1f}%"],
            check=True,
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error setting volume: {e}", file=sys.stderr)
        return False


def volume_get() -> float | None:
    """Get current volume percentage."""
    if is_macos():
        return volume_get_macos()
    elif is_linux():
        return volume_get_linux()
    else:
        print("Volume control only available on macOS and Linux", file=sys.stderr)
        return None


def volume_set(percent: float) -> bool:
    """Set volume percentage."""
    if is_macos():
        return volume_set_macos(percent)
    elif is_linux():
        return volume_set_linux(percent)
    else:
        print("Volume control only available on macOS and Linux", file=sys.stderr)
        return False


def register(cli):
    @cli.command()
    @click.option("--status", is_flag=True, help="Show current volume level")
    @click.argument("level", required=False, type=float)
    def volume(status, level):
        """Get or set system volume (macOS + Linux)"""
        if not is_macos() and not is_linux():
            print("Volume settings only available on macOS and Linux", file=sys.stderr)
            sys.exit(1)

        if status:
            vol = volume_get()
            if vol is not None:
                print(f"Volume: {vol:.0f}%")
                return
            else:
                print("Could not get volume", file=sys.stderr)
                sys.exit(1)

        if level is not None:
            if volume_set(level):
                print(f"Volume: {level:.1f}%")
                return
            sys.exit(1)

        # Default: show status
        vol = volume_get()
        if vol is not None:
            print(f"Volume: {vol:.0f}%")
        else:
            print("Could not get volume", file=sys.stderr)
            sys.exit(1)
