"""Full Disk Access: Manage Full Disk Access permissions (macOS only)."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import click

from common import _get_state_dir, is_macos

FDA_URL = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"

TCC_DB = "/Library/Application Support/com.apple.TCC/TCC.db"


def fda_list() -> list[dict]:
    """List apps in Full Disk Access with their enabled status via TCC database."""
    import sqlite3

    try:
        conn = sqlite3.connect(TCC_DB)
        rows = conn.execute(
            "SELECT client, auth_value FROM access WHERE service='kTCCServiceSystemPolicyAllFiles'"
        ).fetchall()
        conn.close()
        return [
            {"name": client, "enabled": auth_value == 2} for client, auth_value in rows
        ]
    except sqlite3.Error:
        return []


def fda_toggle(app_name: str) -> bool | None:
    """Toggle an app's Full Disk Access permission on/off. Returns new state or None."""
    script = f"""
tell application "System Settings" to quit
delay 0.5
do shell script "open '{FDA_URL}'"
delay 3
tell application "System Events"
    tell process "System Settings"
        set frontmost to true
        set theOutline to outline 1 of scroll area 1 of group 1 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of window 1
        set allRows to every row of theOutline
        repeat with r in allRows
            set rowElements to entire contents of r
            repeat with el in rowElements
                if class of el is checkbox then
                    if name of el is "{app_name}" then
                        click el
                        delay 0.5
                        return value of el as string
                    end if
                end if
            end repeat
        end repeat
        return "not found"
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
        subprocess.run(
            ["osascript", "-e", 'tell application "System Settings" to quit'],
            capture_output=True,
        )
        val = result.stdout.strip()
        if val in ("0", "1"):
            return val == "1"
        return None
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        subprocess.run(
            ["osascript", "-e", 'tell application "System Settings" to quit'],
            capture_output=True,
        )
        return None


def fda_open() -> None:
    """Open the Full Disk Access pane in System Settings."""
    subprocess.run(["open", FDA_URL], check=True)


def fda_state_file() -> Path:
    return _get_state_dir() / "fda-enabled"


def fda_state_matches(enable_apps: list[str]) -> bool:
    state = fda_state_file()
    if not state.exists():
        return False
    return state.read_text().strip() == ",".join(sorted(enable_apps))


def fda_write_state(enable_apps: list[str]) -> None:
    state = fda_state_file()
    state.write_text(",".join(sorted(enable_apps)))


def fda_enable(enable_apps: list[str]) -> None:
    """Ensure specified apps are enabled in Full Disk Access in a single UI session."""
    if fda_state_matches(enable_apps):
        print("Skipping Full Disk Access enable (already configured)")
        return

    enable_checks = " or ".join(f'name of el is "{app}"' for app in enable_apps)
    script = f"""
tell application "System Settings" to quit
delay 0.5
do shell script "open '{FDA_URL}'"
delay 3
tell application "System Events"
    tell process "System Settings"
        set frontmost to true
        set output to ""
        set theOutline to outline 1 of scroll area 1 of group 1 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of window 1
        set allRows to every row of theOutline
        repeat with r in allRows
            set rowElements to entire contents of r
            repeat with el in rowElements
                if class of el is checkbox then
                    if {enable_checks} then
                        set appName to name of el
                        set appVal to value of el
                        if appVal is 0 then
                            click el
                            delay 2
                            repeat 120 times
                                delay 1
                                set sheetCount to count of sheets of window 1
                                if sheetCount is 0 then exit repeat
                            end repeat
                            delay 0.5
                            set output to output & appName & ":enabled" & linefeed
                        else
                            set output to output & appName & ":already enabled" & linefeed
                        end if
                    end if
                end if
            end repeat
        end repeat
        return output
    end tell
end tell
"""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            timeout=300,
        )
        if result.returncode == 0 and result.stdout.strip():
            for line in result.stdout.strip().splitlines():
                if ":" in line:
                    name, status = line.rsplit(":", 1)
                    print(f"  {name.strip()}: {status.strip()}")
        elif result.returncode != 0:
            print("Skipping FDA init (could not read UI)", file=sys.stderr)
            if result.stderr:
                print(f"  {result.stderr.strip()}", file=sys.stderr)
        else:
            for app in enable_apps:
                print(f"  {app}: not found in Full Disk Access list")
        if result.returncode == 0:
            try:
                fda_write_state(enable_apps)
            except Exception as e:
                print(f"Warning: could not write state: {e}", file=sys.stderr)
    except subprocess.TimeoutExpired:
        print("Skipping FDA enable (timeout)", file=sys.stderr)
    finally:
        subprocess.run(
            ["osascript", "-e", 'tell application "System Settings" to quit'],
            capture_output=True,
        )


def register(cli):
    @cli.command()
    @click.option(
        "--enable",
        "enable_apps",
        help="Comma-separated list of apps to enable (idempotent)",
    )
    @click.argument(
        "action", required=False, type=click.Choice(["list", "toggle", "open"])
    )
    @click.argument("app", required=False)
    def fulldiskaccess(enable_apps, action, app):
        """Manage Full Disk Access permissions (macOS only)"""
        if not is_macos():
            print("Full Disk Access settings only available on macOS", file=sys.stderr)
            sys.exit(1)

        if enable_apps:
            apps = [a.strip() for a in enable_apps.split(",")]
            fda_enable(apps)
            return

        if action == "open":
            fda_open()
            return

        if action == "list":
            items = fda_list()
            if not items:
                print("No Full Disk Access items found (or could not read)")
            else:
                for item in items:
                    status = "enabled" if item["enabled"] else "disabled"
                    print(f"  {item['name']}: {status}")
            return

        if action == "toggle":
            if not app:
                print("Error: specify app name to toggle", file=sys.stderr)
                sys.exit(1)
            result = fda_toggle(app)
            if result is not None:
                status = "enabled" if result else "disabled"
                print(f"{app}: {status}")
            else:
                print(f"Could not toggle {app} (not found)", file=sys.stderr)
                sys.exit(1)
            return

        click.echo(click.get_current_context().get_help())
