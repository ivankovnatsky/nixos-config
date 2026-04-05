"""Menubar: Visibility Modes (macOS only)."""

from __future__ import annotations

import subprocess
import sys

import click

from common import is_macos

# Maps mode name -> (defaults option value, UI description)
MENUBAR_MODES = {
    "never": (0, "Never"),
    "always": (1, "Always"),
    "fullscreen": (2, "In Full Screen Only"),
    "desktop": (3, "On Desktop Only"),
}

MENUBAR_OPTION_TO_MODE = {v[0]: k for k, v in MENUBAR_MODES.items()}


def menubar_get_current_mode() -> str:
    """Get current menubar visibility mode via defaults."""
    try:
        result = subprocess.run(
            ["defaults", "read", "com.apple.controlcenter", "AutoHideMenuBarOption"],
            capture_output=True,
            text=True,
        )
        option = int(result.stdout.strip())
        return MENUBAR_OPTION_TO_MODE.get(option, "unknown")
    except (subprocess.CalledProcessError, ValueError):
        return "unknown"


def menubar_get_description(mode: str) -> str:
    """Get human-readable description for a menubar mode."""
    return MENUBAR_MODES.get(mode, (None, "Unknown"))[1]


def menubar_set_mode(mode: str) -> None:
    """Set menubar visibility mode via osascript."""
    menu_item = menubar_get_description(mode)

    subprocess.run(
        [
            "open",
            "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension",
        ],
        check=True,
    )

    script = f"""
delay 0.8
tell application "System Events"
    tell process "System Settings"
        set thePopup to pop up button "Automatically hide and show the menu bar" of group 1 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of window 1
        click thePopup
        delay 0.3
        click menu item "{menu_item}" of menu 1 of thePopup
    end tell
end tell
delay 0.2
tell application "System Settings" to quit
"""
    subprocess.run(["osascript", "-e", script], check=True)


def menubar_cycle_mode() -> None:
    """Toggle between fullscreen and desktop modes."""
    current = menubar_get_current_mode()

    if current == "fullscreen":
        next_mode = "desktop"
    else:
        next_mode = "fullscreen"

    menubar_set_mode(next_mode)
    print(f"Menubar: {menubar_get_description(next_mode)}")


def register(cli):
    @cli.command()
    @click.option("--status", is_flag=True, help="Show current menubar mode")
    @click.argument(
        "mode",
        required=False,
        type=click.Choice(["always", "desktop", "fullscreen", "never"]),
    )
    def menubar(status, mode):
        """Toggle menubar visibility (macOS only)"""
        if not is_macos():
            print("Menubar settings only available on macOS", file=sys.stderr)
            sys.exit(1)

        if status:
            current = menubar_get_current_mode()
            desc = menubar_get_description(current)
            print(f"Current: {current} ({desc})")
            return

        if mode:
            if mode not in MENUBAR_MODES:
                print(f"Unknown mode: {mode}", file=sys.stderr)
                sys.exit(1)
            menubar_set_mode(mode)
            print(f"Menubar: {menubar_get_description(mode)}")
            return

        menubar_cycle_mode()
