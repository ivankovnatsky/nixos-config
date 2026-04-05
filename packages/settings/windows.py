"""Windows: Close/hide/quit/open/restart app windows (macOS only)."""

from __future__ import annotations

import subprocess
import sys
import time

import click

from common import is_macos


def windows_find_process(app_name: str) -> str | None:
    """Find exact process name matching case-insensitively."""
    script = """
tell application "System Events"
    get name of every process
end tell
"""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            check=True,
        )
        for name in result.stdout.strip().split(", "):
            if name.strip().lower() == app_name.lower():
                return name.strip()
        return None
    except subprocess.CalledProcessError:
        return None


def windows_close(app_name: str) -> bool:
    """Close all windows of an app using Cmd+Option+W keystroke.

    Works across Spaces and with SwiftUI apps that don't expose
    standard window elements to the accessibility API.
    App name matching is case-insensitive.
    """
    exact_name = windows_find_process(app_name)
    if not exact_name:
        return False

    script = f"""
tell application "System Events"
    tell process "{exact_name}"
        set frontmost to true
        delay 0.5
        keystroke "w" using {{command down, option down}}
        delay 0.2
        set visible to false
        return "closed"
    end tell
end tell
"""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
        )
        return "closed" in result.stdout
    except subprocess.CalledProcessError:
        return False


def windows_quit(app_name: str) -> bool:
    """Quit an app using Cmd+Q keystroke.

    Sends Cmd+Q then verifies the process has exited.
    Works across Spaces. App name matching is case-insensitive.
    """
    exact_name = windows_find_process(app_name)
    if not exact_name:
        return False

    script = f"""
tell application "System Events"
    tell process "{exact_name}"
        set frontmost to true
        delay 0.5
        keystroke "q" using command down
    end tell
end tell
"""
    try:
        subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError:
        return False

    # Wait up to 5 seconds for the process to actually exit
    for _ in range(10):
        time.sleep(0.5)
        if not windows_find_process(app_name):
            return True
    return False


def windows_open(app_name: str) -> bool:
    """Open/launch an app. Case-insensitive."""
    try:
        subprocess.run(
            ["open", "-a", app_name],
            capture_output=True,
            text=True,
            check=True,
        )
        return True
    except subprocess.CalledProcessError:
        return False


def windows_restart(app_name: str) -> bool:
    """Quit an app and relaunch it. Case-insensitive."""
    if windows_find_process(app_name):
        if not windows_quit(app_name):
            return False
    return windows_open(app_name)


def windows_hide(app_name: str) -> bool:
    """Hide an app (minimize all windows). Case-insensitive."""
    exact_name = windows_find_process(app_name)
    if not exact_name:
        return False

    script = f"""
tell application "System Events"
    set visible of process "{exact_name}" to false
    return "hidden"
end tell
"""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
        )
        return "hidden" in result.stdout
    except subprocess.CalledProcessError:
        return False


def windows_list() -> list[str]:
    """List apps with visible windows."""
    script = """
tell application "System Events"
    set visibleApps to {}
    repeat with p in (processes whose visible is true)
        set end of visibleApps to name of p
    end repeat
    return visibleApps
end tell
"""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            check=True,
        )
        apps = result.stdout.strip().split(", ")
        return [a.strip() for a in apps if a.strip()]
    except subprocess.CalledProcessError:
        return []


def register(cli):
    @cli.command()
    @click.argument(
        "action",
        type=click.Choice(["list", "close", "quit", "hide", "open", "restart"]),
    )
    @click.argument("apps", nargs=-1)
    @click.option(
        "--wait",
        default=0,
        type=int,
        help="Poll interval in seconds; retry until success or timeout (18 attempts)",
    )
    def windows(action, apps, wait):
        """Close/hide/quit/open/restart app windows (macOS only)"""
        if not is_macos():
            print("Windows management only available on macOS", file=sys.stderr)
            sys.exit(1)

        if action == "list":
            app_list = windows_list()
            if app_list:
                print("Apps with visible windows:")
                for app in app_list:
                    print(f"  - {app}")
            else:
                print("No apps with visible windows")
            return

        if action == "close":
            if not apps:
                print("Error: app name(s) required for close action", file=sys.stderr)
                sys.exit(1)
            remaining = list(apps)
            max_attempts = 18 if wait > 0 else 1
            for attempt in range(1, max_attempts + 1):
                still_remaining = []
                for app in remaining:
                    if windows_close(app):
                        print(f"Closed windows of {app}")
                    else:
                        still_remaining.append(app)
                remaining = still_remaining
                if not remaining:
                    return
                if attempt < max_attempts:
                    time.sleep(wait)
            for app in remaining:
                print(f"Could not close windows of {app} (not running or no windows)")
            sys.exit(1)

        if action == "quit":
            if not apps:
                print("Error: app name(s) required for quit action", file=sys.stderr)
                sys.exit(1)
            remaining = list(apps)
            max_attempts = 18 if wait > 0 else 1
            for attempt in range(1, max_attempts + 1):
                still_remaining = []
                for app in remaining:
                    if windows_quit(app):
                        print(f"Quit {app}")
                    else:
                        still_remaining.append(app)
                remaining = still_remaining
                if not remaining:
                    return
                if attempt < max_attempts:
                    time.sleep(wait)
            for app in remaining:
                print(f"Could not quit {app} (not running)")
            sys.exit(1)

        if action == "hide":
            if not apps:
                print("Error: app name(s) required for hide action", file=sys.stderr)
                sys.exit(1)
            for app in apps:
                if windows_hide(app):
                    print(f"Hidden {app}")
                else:
                    print(f"Could not hide {app} (not running)")
            return

        if action == "open":
            if not apps:
                print("Error: app name(s) required for open action", file=sys.stderr)
                sys.exit(1)
            for app in apps:
                if windows_open(app):
                    print(f"Opened {app}")
                else:
                    print(f"Could not open {app}")
            return

        if action == "restart":
            if not apps:
                print("Error: app name(s) required for restart action", file=sys.stderr)
                sys.exit(1)
            for app in apps:
                if windows_restart(app):
                    print(f"Restarted {app}")
                else:
                    print(f"Could not restart {app}")
            return

        print("Unknown action", file=sys.stderr)
        sys.exit(1)
