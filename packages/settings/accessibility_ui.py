"""AppleScript-driven UI primitives for the Accessibility pane (macOS only)."""

from __future__ import annotations

import subprocess
import sys

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
