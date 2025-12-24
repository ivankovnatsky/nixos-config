#!/usr/bin/env python3

import subprocess
import sys

MODE_DESCRIPTIONS = {
    "never": "Never",
    "always": "Always",
    "fullscreen": "In Full Screen Only",
    "desktop": "On Desktop Only",
}

# Maps our mode names to the exact menu item text in System Settings
MODE_TO_MENU_ITEM = {
    "never": "Never",
    "always": "Always",
    "fullscreen": "In Full Screen Only",
    "desktop": "On Desktop Only",
}


def get_current_mode() -> str:
    """Get current menubar visibility mode via osascript."""
    script = '''
tell application "System Settings"
    activate
    delay 0.5
end tell
tell application "System Events"
    tell process "System Settings"
        set thePopup to pop up button "Automatically hide and show the menu bar" of group 1 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of window 1
        return value of thePopup
    end tell
end tell
'''
    result = subprocess.run(
        ["osascript", "-e", script],
        capture_output=True,
        text=True,
    )
    value = result.stdout.strip()

    # Map menu item text back to our mode name
    for mode, menu_text in MODE_TO_MENU_ITEM.items():
        if menu_text == value:
            return mode
    return "unknown"


def set_mode(mode: str) -> None:
    """Set menubar visibility mode via osascript."""
    menu_item = MODE_TO_MENU_ITEM[mode]

    # Open Menu Bar settings via URL scheme
    subprocess.run(
        ["open", "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension"],
        check=True,
    )

    script = f'''
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
'''
    subprocess.run(["osascript", "-e", script], check=True)


def print_usage() -> None:
    print("Usage: switch-menubar [mode]")
    print()
    print("Modes:")
    for mode, desc in MODE_DESCRIPTIONS.items():
        print(f"  {mode:12} - {desc}")
    print()
    print("Without arguments, cycles to next mode.")


def cycle_mode() -> None:
    """Cycle through modes in order: never -> fullscreen -> desktop -> always -> never."""
    cycle_order = ["never", "fullscreen", "desktop", "always"]
    current = get_current_mode()

    if current in cycle_order:
        idx = cycle_order.index(current)
        next_mode = cycle_order[(idx + 1) % len(cycle_order)]
    else:
        next_mode = "never"

    set_mode(next_mode)
    print(f"Menubar: {MODE_DESCRIPTIONS[next_mode]}")


def main() -> None:
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower()

        if arg in ("--help", "-h"):
            print_usage()
            return

        if arg == "status":
            current = get_current_mode()
            desc = MODE_DESCRIPTIONS.get(current, "Unknown")
            print(f"Current: {current} ({desc})")
            return

        if arg in MODE_TO_MENU_ITEM:
            set_mode(arg)
            print(f"Menubar: {MODE_DESCRIPTIONS[arg]}")
            return

        print(f"Unknown mode: {arg}", file=sys.stderr)
        print_usage()
        sys.exit(1)
    else:
        cycle_mode()


if __name__ == "__main__":
    main()
