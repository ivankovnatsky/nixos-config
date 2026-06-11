"""Accessibility state-file persistence and declarative enable/set orchestrators."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from accessibility_ui import (
    ACCESSIBILITY_URL,
    accessibility_list,
    accessibility_remove,
)
from common import _get_state_dir, quit_app


def accessibility_state_file() -> Path:
    return _get_state_dir() / "accessibility-enabled"


def accessibility_state_matches(enable_apps: list[str]) -> bool:
    """Check if state file matches the requested app list."""
    state = accessibility_state_file()
    if not state.exists():
        return False
    return state.read_text().strip() == ",".join(sorted(enable_apps))


def accessibility_write_state(enable_apps: list[str]) -> None:
    state = accessibility_state_file()
    state.write_text(",".join(sorted(enable_apps)))


def accessibility_previous_state() -> list[str]:
    state = accessibility_state_file()
    if not state.exists():
        return []
    raw = state.read_text().strip()
    if not raw:
        return []
    return [a.strip() for a in raw.split(",") if a.strip()]


def accessibility_enable(enable_apps: list[str]) -> None:
    """Ensure specified apps are enabled in Accessibility in a single UI session."""
    if accessibility_state_matches(enable_apps):
        print("Skipping accessibility enable (already configured)")
        return

    enable_checks = " or ".join(f'name of el is "{app}"' for app in enable_apps)
    script = f"""
tell application "System Settings" to quit
delay 0.5
do shell script "open '{ACCESSIBILITY_URL}'"
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
                            -- Wait for password sheet to appear
                            delay 2
                            -- Wait for password sheet to be dismissed (up to 120s)
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
            print("Skipping accessibility init (could not read UI)", file=sys.stderr)
            if result.stderr:
                print(f"  {result.stderr.strip()}", file=sys.stderr)
        else:
            for app in enable_apps:
                print(f"  {app}: not found in accessibility list")
        if result.returncode == 0:
            try:
                accessibility_write_state(enable_apps)
            except Exception as e:
                print(f"Warning: could not write state: {e}", file=sys.stderr)
    except subprocess.TimeoutExpired:
        print("Skipping accessibility enable (timeout)", file=sys.stderr)
    finally:
        subprocess.run(
            ["osascript", "-e", 'tell application "System Settings" to quit'],
            capture_output=True,
        )


def accessibility_set(target_apps: list[str]) -> None:
    """Sync accessibility permissions to exactly target_apps (declarative).

    Removes apps previously managed by us (per state file) that are no longer
    in target_apps, then enables target_apps. User-added entries are preserved.
    """
    if accessibility_state_matches(target_apps):
        print("Skipping accessibility set (already configured)")
        return

    target = set(target_apps)
    previously_managed = set(accessibility_previous_state())
    to_remove = previously_managed - target

    if to_remove:
        current = {item["name"] for item in accessibility_list()}
        for app in sorted(to_remove):
            if app not in current:
                continue
            if accessibility_remove(app):
                print(f"Removed accessibility entry: {app}")
                if quit_app(app):
                    print(f"Quit running app: {app}")
            else:
                print(
                    f"Could not remove accessibility entry: {app}",
                    file=sys.stderr,
                )

    accessibility_enable(target_apps)
