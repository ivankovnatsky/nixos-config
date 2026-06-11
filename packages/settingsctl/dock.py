"""Dock: Toggle dock autohide (macOS only)."""

from __future__ import annotations

import subprocess
import sys

import click

from common import is_macos


def dock_get_autohide() -> bool:
    """Check if dock autohide is enabled."""
    try:
        result = subprocess.run(
            ["defaults", "read", "com.apple.dock", "autohide"],
            capture_output=True,
            text=True,
        )
        return result.stdout.strip() == "1"
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def dock_set_autohide(enabled: bool) -> bool:
    """Set dock autohide and restart dock."""
    try:
        subprocess.run(
            [
                "defaults",
                "write",
                "com.apple.dock",
                "autohide",
                "-bool",
                str(enabled).lower(),
            ],
            check=True,
        )
        subprocess.run(["killall", "Dock"], check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error setting dock autohide: {e}", file=sys.stderr)
        return False


def dock_toggle() -> int:
    """Toggle dock visibility."""
    current = dock_get_autohide()
    if dock_set_autohide(not current):
        status = "hidden" if not current else "visible"
        print(f"Dock is now {status}")
        return 0
    return 1


def register(cli):
    @cli.command()
    @click.option("--status", is_flag=True, help="Show current dock autohide status")
    def dock(status):
        """Toggle dock autohide (macOS only)"""
        if not is_macos():
            print("Dock settings only available on macOS", file=sys.stderr)
            sys.exit(1)

        if status:
            hidden = dock_get_autohide()
            status_str = "hidden (auto-hide enabled)" if hidden else "visible"
            print(f"Dock: {status_str}")
            return

        result = dock_toggle()
        if result != 0:
            sys.exit(result)
