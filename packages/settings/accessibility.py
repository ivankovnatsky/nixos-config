"""Accessibility: Manage accessibility permissions (macOS only)."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import click

from common import _get_state_dir, is_macos

ACCESSIBILITY_URL = (
    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
)


def accessibility_list() -> list[dict]:
    """List apps in Accessibility with their enabled status."""
    script = (
        """
tell application "System Settings" to quit
delay 0.5
do shell script "open '"""
        + ACCESSIBILITY_URL
        + """'"
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
                    set appName to name of el
                    set appEnabled to value of el
                    set output to output & appName & ":" & appEnabled & linefeed
                end if
            end repeat
        end repeat
        return output
    end tell
end tell
"""
    )
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
        items = []
        if result.returncode == 0:
            for line in result.stdout.strip().splitlines():
                if ":" in line:
                    name, val = line.rsplit(":", 1)
                    items.append({"name": name.strip(), "enabled": val.strip() == "1"})
        return items
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        subprocess.run(
            ["osascript", "-e", 'tell application "System Settings" to quit'],
            capture_output=True,
        )
        return []


def accessibility_add(app_path: str) -> bool:
    """Add an app to Accessibility via UI automation (click +, select app)."""
    script = f"""
tell application "System Settings" to quit
delay 0.5
do shell script "open '{ACCESSIBILITY_URL}'"
delay 3
tell application "System Events"
    tell process "System Settings"
        set frontmost to true
        set parentGroup to group 1 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of window 1
        -- Click the first button (+/add)
        click button 1 of parentGroup
        -- Wait for password sheet and user to authenticate
        delay 5

        -- Check if a file open sheet appeared
        set sheetCount to count of sheets of window 1
        if sheetCount is 0 then
            return "no dialog"
        end if

        -- Use Go to Folder to navigate
        keystroke "g" using {{command down, shift down}}
        delay 1
        keystroke "{app_path}"
        delay 0.5
        keystroke return
        delay 1
        -- Click Open button
        click button "Open" of sheet 1 of window 1
        delay 1
        return "added"
    end tell
end tell
"""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            timeout=60,
        )
        subprocess.run(
            ["osascript", "-e", 'tell application "System Settings" to quit'],
            capture_output=True,
        )
        if result.stderr:
            print(f"  {result.stderr.strip()}", file=sys.stderr)
        return "added" in result.stdout
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        subprocess.run(
            ["osascript", "-e", 'tell application "System Settings" to quit'],
            capture_output=True,
        )
        return False


def accessibility_remove(app_name: str) -> bool:
    """Remove an app from Accessibility by selecting it and clicking minus."""
    script = f"""
tell application "System Settings" to quit
delay 0.5
do shell script "open '{ACCESSIBILITY_URL}'"
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
                        -- Select the row first
                        select r
                        delay 0.3
                        -- Click the remove (-) button in the parent group
                        set parentGroup to group 1 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of window 1
                        set allButtons to every button of parentGroup
                        repeat with btn in allButtons
                            try
                                click btn
                                delay 0.5
                                return "removed"
                            end try
                        end repeat
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
        return "removed" in result.stdout
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        subprocess.run(
            ["osascript", "-e", 'tell application "System Settings" to quit'],
            capture_output=True,
        )
        return False


def accessibility_toggle(app_name: str) -> bool | None:
    """Toggle an app's accessibility permission on/off. Returns new state or None."""
    script = f"""
tell application "System Settings" to quit
delay 0.5
do shell script "open '{ACCESSIBILITY_URL}'"
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


def accessibility_open() -> None:
    """Open the Accessibility pane in System Settings."""
    subprocess.run(["open", ACCESSIBILITY_URL], check=True)


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


def accessibility_previous_state() -> list[str]:
    state = accessibility_state_file()
    if not state.exists():
        return []
    raw = state.read_text().strip()
    if not raw:
        return []
    return [a.strip() for a in raw.split(",") if a.strip()]


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


def register(cli):
    @cli.command()
    @click.argument(
        "action",
        required=False,
        type=click.Choice(["list", "add", "remove", "toggle", "open", "enable", "set"]),
    )
    @click.argument("app", required=False)
    def accessibility(action, app):
        """Manage accessibility permissions (macOS only)

        Actions:
          list                    Show all entries and their enabled state
          add APP                 Add an app entry (UI automation; may prompt)
          remove APP              Remove an app entry
          toggle APP              Toggle an app's enabled state
          enable "APP1,APP2,..."  Enable apps (idempotent, additive)
          set "APP1,APP2,..."     Declaratively sync to list; removes previously
                                  managed apps no longer in the list
          open                    Open the Accessibility pane in System Settings
        """
        if not is_macos():
            print("Accessibility settings only available on macOS", file=sys.stderr)
            sys.exit(1)

        if action == "set":
            if app is None:
                print(
                    "Error: specify app list (use empty string for none)",
                    file=sys.stderr,
                )
                sys.exit(1)
            apps = [a.strip() for a in app.split(",") if a.strip()]
            accessibility_set(apps)
            return

        if action == "enable":
            if not app:
                print("Error: specify app list", file=sys.stderr)
                sys.exit(1)
            apps = [a.strip() for a in app.split(",") if a.strip()]
            accessibility_enable(apps)
            return

        if action == "open":
            accessibility_open()
            return

        if action == "list":
            items = accessibility_list()
            if not items:
                print("No accessibility items found (or could not read)")
            else:
                for item in items:
                    status = "enabled" if item["enabled"] else "disabled"
                    print(f"  {item['name']}: {status}")
            return

        if action == "add":
            if not app:
                print(
                    "Error: specify app path (e.g. /Applications/Amethyst.app)",
                    file=sys.stderr,
                )
                sys.exit(1)
            app_path = app
            if not app_path.startswith("/"):
                app_path = f"/Applications/{app}.app"
            if not Path(app_path).exists():
                print(f"Error: {app_path} does not exist", file=sys.stderr)
                sys.exit(1)
            if accessibility_add(app_path):
                print(f"Added {app_path} to Accessibility")
            else:
                print(
                    f"Could not add {app_path} (may need manual approval)",
                    file=sys.stderr,
                )
                sys.exit(1)
            return

        if action == "remove":
            if not app:
                print("Error: specify app name to remove", file=sys.stderr)
                sys.exit(1)
            if accessibility_remove(app):
                print(f"Removed {app} from Accessibility")
            else:
                print(f"Could not remove {app} (not found or failed)", file=sys.stderr)
                sys.exit(1)
            return

        if action == "toggle":
            if not app:
                print("Error: specify app name to toggle", file=sys.stderr)
                sys.exit(1)
            result = accessibility_toggle(app)
            if result is not None:
                status = "enabled" if result else "disabled"
                print(f"{app}: {status}")
            else:
                print(f"Could not toggle {app} (not found)", file=sys.stderr)
                sys.exit(1)
            return

        click.echo(click.get_current_context().get_help())
