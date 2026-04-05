"""Location: Toggle Location Services (macOS only)."""

from __future__ import annotations

import subprocess
import sys

import click

from common import is_macos

LOCATION_SERVICES_URL = (
    "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
)


def location_check_enabled() -> bool | None:
    """Check Location Services status via CoreLocation (no UI, no sudo)."""
    try:
        result = subprocess.run(
            [
                "/usr/bin/swift",
                "-e",
                "import CoreLocation; print(CLLocationManager.locationServicesEnabled())",
            ],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0:
            return result.stdout.strip() == "true"
        return None
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None


def location_osascript(action: str) -> tuple[bool, int | None]:
    """Open Location Services pane and get/toggle the main switch.

    action: "toggle" to flip, "on" to enable, "off" to disable.
    Returns (success, value) where value is 0/1 or None on failure.
    """
    # Build the AppleScript action block
    if action == "on":
        action_block = """
                if value of firstCheckbox is 0 then
                    click firstCheckbox
                    delay 2
                end if
                return value of firstCheckbox"""
    elif action == "off":
        action_block = """
                if value of firstCheckbox is 1 then
                    click firstCheckbox
                    delay 2
                end if
                return value of firstCheckbox"""
    else:
        action_block = """
                click firstCheckbox
                delay 2
                return value of firstCheckbox"""

    script = f"""
tell application "System Settings" to quit
delay 0.5
do shell script "open '{LOCATION_SERVICES_URL}'"
delay 2
tell application "System Events"
    tell process "System Settings"
        set frontmost to true
        set allElements to entire contents of window 1
        repeat with el in allElements
            if class of el is checkbox then
                set firstCheckbox to el
                {action_block}
            end if
        end repeat
    end tell
end tell
"""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            timeout=30,
        )
        # Close System Settings after
        subprocess.run(
            ["osascript", "-e", 'tell application "System Settings" to quit'],
            capture_output=True,
        )
        if result.returncode == 0:
            val = result.stdout.strip()
            if val in ("0", "1"):
                return True, int(val)
        return False, None
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
        subprocess.run(
            ["osascript", "-e", 'tell application "System Settings" to quit'],
            capture_output=True,
        )
        print(f"Error: {e}", file=sys.stderr)
        return False, None


def register(cli):
    @cli.command()
    @click.option(
        "--status", is_flag=True, help="Show current Location Services status"
    )
    @click.option(
        "--init",
        is_flag=True,
        help="Enable Location Services if not already enabled (idempotent, for activation scripts)",
    )
    @click.argument("mode", required=False, type=click.Choice(["on", "off"]))
    def location(status, init, mode):
        """Toggle Location Services (macOS only)"""
        if not is_macos():
            print("Location Services only available on macOS", file=sys.stderr)
            sys.exit(1)

        if status:
            enabled = location_check_enabled()
            if enabled is not None:
                status_str = "enabled" if enabled else "disabled"
                print(f"Location Services: {status_str}")
                return
            print("Could not read Location Services status", file=sys.stderr)
            sys.exit(1)

        if init:
            enabled = location_check_enabled()
            if enabled is True:
                print("Location Services: already enabled")
                return
            if enabled is None:
                print(
                    "Could not check Location Services status, skipping",
                    file=sys.stderr,
                )
                return
            print(
                "Location Services is disabled. Enable manually: settings location on"
            )
            return

        # Always check current state via Swift before touching UI
        enabled = location_check_enabled()
        if enabled is None:
            print("Could not read Location Services status", file=sys.stderr)
            sys.exit(1)

        if mode == "on" and enabled:
            print("Location Services: already enabled")
            return
        if mode == "off" and not enabled:
            print("Location Services: already disabled")
            return

        # Determine action: explicit mode or toggle
        if mode:
            action = mode
        else:
            action = "off" if enabled else "on"

        ok, val = location_osascript(action)
        if ok and val is not None:
            status_str = "enabled" if val == 1 else "disabled"
            print(f"Location Services: {status_str}")

            if val == 1 and not enabled:
                print("Opening Weather app to initialize location...")
                subprocess.run(["open", "-a", "Weather"], check=False)

            return

        print(
            "Could not toggle Location Services (authentication may be required)",
            file=sys.stderr,
        )
        sys.exit(1)
