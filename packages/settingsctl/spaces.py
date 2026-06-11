"""Spaces: Add/remove desktop spaces (macOS only)."""

from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

import click

from common import is_macos

SPACES_PLIST = Path.home() / "Library/Preferences/com.apple.spaces.plist"


def spaces_get_current_index() -> int | None:
    """Get the 1-based index of the current desktop space."""
    import json

    try:
        result = subprocess.run(
            ["plutil", "-convert", "json", "-o", "-", str(SPACES_PLIST)],
            capture_output=True,
            text=True,
            check=True,
        )
        data = json.loads(result.stdout)

        config = data.get("SpacesDisplayConfiguration", {})
        mgmt_data = config.get("Management Data", {})
        monitors = mgmt_data.get("Monitors", [])

        for monitor in monitors:
            if "Current Space" not in monitor:
                continue

            current_id = monitor["Current Space"].get("ManagedSpaceID")
            if current_id is None:
                continue

            spaces = [s for s in monitor.get("Spaces", []) if s.get("type") == 0]
            for idx, space in enumerate(spaces):
                if space.get("ManagedSpaceID") == current_id:
                    return idx + 1

        return None
    except (subprocess.CalledProcessError, json.JSONDecodeError, KeyError):
        return None


def spaces_count() -> int | None:
    """Get the number of desktop spaces on the primary monitor (excluding fullscreen apps)."""
    import json

    try:
        result = subprocess.run(
            ["plutil", "-convert", "json", "-o", "-", str(SPACES_PLIST)],
            capture_output=True,
            text=True,
            check=True,
        )
        data = json.loads(result.stdout)

        config = data.get("SpacesDisplayConfiguration", {})
        mgmt_data = config.get("Management Data", {})
        monitors = mgmt_data.get("Monitors", [])

        # Find the monitor with Current Space (the primary/active one),
        # consistent with spaces_get_current_index() iteration
        for monitor in monitors:
            if "Current Space" in monitor:
                spaces = [s for s in monitor.get("Spaces", []) if s.get("type") == 0]
                return len(spaces)

        return None
    except (subprocess.CalledProcessError, json.JSONDecodeError, KeyError):
        return None


def spaces_ensure(target: int) -> int:
    """Ensure exactly `target` desktop spaces exist (idempotent)."""
    current = spaces_count()
    if current is None:
        print("Error: Could not determine current space count", file=sys.stderr)
        return 1

    if current == target:
        print(f"Already have {target} spaces, nothing to do")
        return 0

    if current < target:
        to_add = target - current
        print(f"Have {current} spaces, adding {to_add} to reach {target}")
        for i in range(to_add):
            rc = spaces_add()
            if rc != 0:
                return rc
            time.sleep(0.5)
    else:
        print(
            f"Have {current} spaces, need {target}. "
            "Removing extra spaces is not supported in ensure mode — remove manually.",
            file=sys.stderr,
        )
        return 1

    time.sleep(1.0)
    final = spaces_count()
    if final is None:
        print("Warning: Could not verify final space count", file=sys.stderr)
        return 1
    if final != target:
        print(
            f"Error: Expected {target} spaces but have {final}",
            file=sys.stderr,
        )
        return 1
    print(f"Now have {final} spaces")
    return 0


def spaces_add() -> int:
    """Add a new desktop space."""
    script = """
tell application "Mission Control" to launch
delay 0.7
tell application "System Events"
  tell group "Spaces Bar" of group 1 of group "Mission Control" of process "Dock"
    click button 1
  end tell
end tell
"""
    try:
        subprocess.run(["osascript", "-e", script], check=True)
        print("Added new desktop space")
        return 0
    except subprocess.CalledProcessError as e:
        print(f"Error adding space: {e}", file=sys.stderr)
        return 1


def spaces_remove() -> int:
    """Remove the current desktop space."""
    index = spaces_get_current_index()
    if index is None:
        print("Error: Could not determine current space index", file=sys.stderr)
        return 1

    script = f"""
tell application "Mission Control" to launch
delay 0.7
tell application "System Events"
  tell list 1 of group "Spaces Bar" of group 1 of group "Mission Control" of process "Dock"
    perform action "AXRemoveDesktop" of button {index}
  end tell
end tell
"""
    for attempt in range(2):
        try:
            subprocess.run(["osascript", "-e", script], check=True)
            print(f"Removed desktop space {index}")
            return 0
        except subprocess.CalledProcessError as e:
            if attempt == 0:
                print("Space removal failed, retrying...", file=sys.stderr)
                time.sleep(1.0)
            else:
                print(f"Error removing space: {e}", file=sys.stderr)
                return 1
    return 1


def register(cli):
    @cli.command()
    @click.argument("action", type=click.Choice(["add", "remove", "ensure", "count"]))
    @click.option(
        "--count",
        "-n",
        "target_count",
        type=int,
        help="Target number of spaces (for ensure)",
    )
    def spaces(action, target_count):
        """Add, remove, count, or ensure desktop spaces (macOS only)"""
        if not is_macos():
            print("Spaces settings only available on macOS", file=sys.stderr)
            sys.exit(1)

        if action == "add":
            result = spaces_add()
        elif action == "remove":
            result = spaces_remove()
        elif action == "count":
            count = spaces_count()
            if count is None:
                print("Error: Could not determine space count", file=sys.stderr)
                sys.exit(1)
            print(count)
            result = 0
        elif action == "ensure":
            if target_count is None:
                print("Usage: settings spaces ensure --count N", file=sys.stderr)
                sys.exit(1)
            result = spaces_ensure(target_count)
        else:
            print("Usage: settings spaces <add|remove|ensure|count>", file=sys.stderr)
            sys.exit(1)

        if result != 0:
            sys.exit(result)
