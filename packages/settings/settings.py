#!/usr/bin/env python3
"""Unified settings tool for toggling system preferences.

Subcommands:
  appearance  Toggle dark/light mode and wallpaper (macOS + KDE)
  menubar     Toggle menubar visibility modes (macOS only)
  scaling     Toggle display scaling resolution (macOS only)
  scrolling   Toggle natural scrolling on/off (macOS only)
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from datetime import date
from pathlib import Path


# Platform Detection
def is_macos() -> bool:
    import platform
    return platform.system() == "Darwin"


def is_kde() -> bool:
    desktop = os.environ.get("XDG_CURRENT_DESKTOP", "")
    if "KDE" in desktop or "Plasma" in desktop:
        return True
    try:
        subprocess.run(["pgrep", "plasmashell"], check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError:
        return False


# Appearance: Dark/Light Mode + Wallpaper
def _get_skylight():
    """Load SkyLight framework for immediate dark mode changes."""
    from ctypes import CDLL, c_bool

    lib = CDLL("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight")
    lib.SLSGetAppearanceThemeLegacy.argtypes = []
    lib.SLSGetAppearanceThemeLegacy.restype = c_bool
    lib.SLSSetAppearanceThemeLegacy.argtypes = [c_bool]
    return lib


def appearance_get_theme_macos() -> bool:
    """Returns True if dark mode is enabled."""
    lib = _get_skylight()
    return lib.SLSGetAppearanceThemeLegacy()


def appearance_set_dark_mode_macos(dark: bool) -> None:
    """Set dark mode using SkyLight framework (takes effect immediately)."""
    lib = _get_skylight()
    lib.SLSSetAppearanceThemeLegacy(dark)


def appearance_set_wallpaper_macos(color: str) -> None:
    file_path = f"/System/Library/Desktop Pictures/Solid Colors/{color}.png"
    script = f'''
tell application "System Events"
    tell every desktop
        set picture to "{file_path}"
    end tell
end tell
'''
    subprocess.run(["osascript", "-e", script], check=True)


def appearance_open_settings_macos() -> None:
    script = '''
tell application "System Settings"
    activate
    delay 0.5
    tell application "System Events"
        tell process "System Settings"
            click menu item "Wallpaper" of menu "View" of menu bar 1
        end tell
    end tell
end tell
'''
    subprocess.run(["osascript", "-e", script], capture_output=True)


def appearance_get_theme_kde() -> bool:
    """Returns True if dark mode is enabled."""
    result = subprocess.run(
        ["plasma-apply-colorscheme", "--list-schemes"],
        capture_output=True,
        text=True,
    )
    for line in result.stdout.split("\n"):
        if "(current color scheme)" in line:
            return "Dark" in line
    return False


def appearance_set_theme_kde(dark: bool) -> None:
    scheme = "BreezeDark" if dark else "BreezeLight"
    subprocess.run(["plasma-apply-colorscheme", scheme], check=True)


def appearance_set_wallpaper_kde(color: str) -> None:
    rgb = "0,0,0" if color == "Black" else "192,192,192"

    list_script = """
var allDesktops = desktops();
var output = [];
for (var i = 0; i < allDesktops.length; i++) {
    var d = allDesktops[i];
    output.push(d.id);
}
output.join(',');
"""
    result = subprocess.run(
        [
            "qdbus",
            "org.kde.plasmashell",
            "/PlasmaShell",
            "org.kde.PlasmaShell.evaluateScript",
            list_script,
        ],
        capture_output=True,
        text=True,
    )

    screens = result.stdout.strip().split(",")
    for screen in screens:
        if not screen:
            continue
        set_script = f"""
var d = desktopById({screen});
d.wallpaperPlugin = 'org.kde.color';
d.currentConfigGroup = ['Wallpaper', 'org.kde.color', 'General'];
d.writeConfig('Color', '{rgb}');
"""
        subprocess.run(
            [
                "qdbus",
                "org.kde.plasmashell",
                "/PlasmaShell",
                "org.kde.PlasmaShell.evaluateScript",
                set_script,
            ],
            capture_output=True,
        )


def appearance_open_settings_kde() -> None:
    subprocess.Popen(["systemsettings", "appearance"])


def appearance_get_state_dir() -> Path:
    return Path.home() / ".local" / "state" / "settings" / "appearance"


def appearance_get_state_file() -> Path:
    return appearance_get_state_dir() / "last-run"


def appearance_write_state() -> None:
    state_dir = appearance_get_state_dir()
    state_dir.mkdir(parents=True, exist_ok=True)
    appearance_get_state_file().write_text(date.today().isoformat())


def appearance_remove_state() -> None:
    try:
        appearance_get_state_file().unlink()
    except FileNotFoundError:
        pass


def appearance_set_dark_mode(dark: bool) -> None:
    if is_macos():
        appearance_set_dark_mode_macos(dark)
        color = "Black" if dark else "Silver"
        appearance_set_wallpaper_macos(color)
    elif is_kde():
        appearance_set_theme_kde(dark)
        color = "Black" if dark else "Silver"
        appearance_set_wallpaper_kde(color)
    else:
        raise RuntimeError("Unsupported platform")


def appearance_get_current_theme() -> bool:
    if is_macos():
        return appearance_get_theme_macos()
    elif is_kde():
        return appearance_get_theme_kde()
    else:
        raise RuntimeError("Unsupported platform")


def appearance_open_settings() -> None:
    if is_macos():
        appearance_open_settings_macos()
    elif is_kde():
        appearance_open_settings_kde()


def cmd_appearance(args: argparse.Namespace) -> int:
    if not is_macos() and not is_kde():
        print("Unsupported platform", file=sys.stderr)
        return 1

    if args.init:
        appearance_set_dark_mode(True)
        print("Set dark mode and wallpaper (init)")
        appearance_remove_state()
        return 0

    is_dark = appearance_get_current_theme()
    new_dark = not is_dark
    appearance_set_dark_mode(new_dark)

    if new_dark:
        print("Switched to Dark appearance")
    else:
        print("Switched to Light appearance")

    try:
        appearance_write_state()
    except Exception as e:
        print(f"Warning: could not write state: {e}", file=sys.stderr)

    try:
        appearance_open_settings()
    except Exception as e:
        print(f"Warning: could not open settings: {e}", file=sys.stderr)

    return 0


# Menubar: Visibility Modes (macOS only)
MENUBAR_MODE_DESCRIPTIONS = {
    "never": "Never",
    "always": "Always",
    "fullscreen": "In Full Screen Only",
    "desktop": "On Desktop Only",
}

def menubar_get_current_mode() -> str:
    """Get current menubar visibility mode via osascript."""
    subprocess.run(
        ["open", "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension"],
        check=True,
    )

    script = '''
delay 0.8
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

    for mode, menu_text in MENUBAR_MODE_DESCRIPTIONS.items():
        if menu_text == value:
            return mode
    return "unknown"


def menubar_set_mode(mode: str) -> None:
    """Set menubar visibility mode via osascript."""
    menu_item = MENUBAR_MODE_DESCRIPTIONS[mode]

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


def menubar_cycle_mode() -> None:
    """Toggle between fullscreen and desktop modes."""
    current = menubar_get_current_mode()

    if current == "fullscreen":
        next_mode = "desktop"
    else:
        next_mode = "fullscreen"

    menubar_set_mode(next_mode)
    print(f"Menubar: {MENUBAR_MODE_DESCRIPTIONS[next_mode]}")


def cmd_menubar(args: argparse.Namespace) -> int:
    if not is_macos():
        print("Menubar settings only available on macOS", file=sys.stderr)
        return 1

    if args.status:
        current = menubar_get_current_mode()
        desc = MENUBAR_MODE_DESCRIPTIONS.get(current, "Unknown")
        print(f"Current: {current} ({desc})")
        return 0

    if args.mode:
        if args.mode not in MENUBAR_MODE_DESCRIPTIONS:
            print(f"Unknown mode: {args.mode}", file=sys.stderr)
            return 1
        menubar_set_mode(args.mode)
        print(f"Menubar: {MENUBAR_MODE_DESCRIPTIONS[args.mode]}")
        return 0

    menubar_cycle_mode()
    return 0


# Scaling: Display Resolution (macOS only)
SCALING_MODEL_RESOLUTIONS = {
    "Mac14,2": ("1470x956", "1280x832"),  # MacBook Air 13" M2
    "Mac15,7": ("1728x1117", "1496x967"),  # MacBook Pro 16" M3
    "MacBookPro18,1": ("1728x1117", "1496x967"),  # MacBook Pro 16" M1 Pro/Max
}


def scaling_get_model_identifier() -> str:
    """Get the Mac model identifier."""
    try:
        result = subprocess.run(
            ["sysctl", "-n", "hw.model"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def scaling_get_displayplacer_output() -> str:
    """Get raw output from displayplacer list."""
    try:
        result = subprocess.run(
            ["displayplacer", "list"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error running displayplacer: {e}", file=sys.stderr)
        return ""


def scaling_parse_displays() -> list[dict]:
    """Parse displayplacer list output into a list of display info dicts."""
    output = scaling_get_displayplacer_output()
    if not output:
        return []

    displays = []
    current_display = {}

    for line in output.splitlines():
        if line.startswith("Persistent screen id:"):
            if current_display:
                displays.append(current_display)
            current_display = {"id": line.split(":", 1)[1].strip(), "modes": []}
        elif line.startswith("Type:"):
            current_display["type"] = line.split(":", 1)[1].strip()
        elif line.startswith("Hertz:"):
            current_display["hz"] = line.split(":", 1)[1].strip()
        elif line.startswith("Color Depth:"):
            current_display["color_depth"] = line.split(":", 1)[1].strip()
        elif line.startswith("Resolution:"):
            current_display["resolution"] = line.split(":", 1)[1].strip()
        elif line.strip().startswith("mode "):
            mode_match = re.search(
                r"res:(\S+)\s+hz:(\d+)\s+color_depth:(\d+)(?:\s+scaling:(\w+))?",
                line,
            )
            if mode_match:
                mode = {
                    "res": mode_match.group(1),
                    "hz": mode_match.group(2),
                    "color_depth": mode_match.group(3),
                    "scaling": mode_match.group(4) == "on",
                    "current": "<-- current mode" in line,
                }
                current_display.setdefault("modes", []).append(mode)
                if mode["current"]:
                    current_display["resolution"] = mode["res"]
                    current_display["hz"] = mode["hz"]
                    current_display["color_depth"] = mode["color_depth"]

    if current_display:
        displays.append(current_display)

    return displays


def scaling_get_builtin_display() -> dict | None:
    """Get the built-in MacBook display info."""
    displays = scaling_parse_displays()
    for display in displays:
        if display.get("type") == "MacBook built in screen":
            return display
    return None


def scaling_get_scaled_modes(display: dict) -> list[dict]:
    """Get all modes with scaling enabled, sorted by resolution (largest first)."""
    modes = [m for m in display.get("modes", []) if m.get("scaling")]
    modes.sort(key=lambda m: scaling_parse_resolution(m["res"]), reverse=True)
    return modes


def scaling_parse_resolution(res: str) -> int:
    """Parse resolution string to pixel count for sorting."""
    try:
        w, h = res.split("x")
        return int(w) * int(h)
    except (ValueError, AttributeError):
        return 0


def scaling_find_mode_by_resolution(display: dict, resolution: str) -> dict | None:
    """Find a mode by resolution string."""
    for mode in display.get("modes", []):
        if mode.get("res") == resolution:
            return mode
    return None


def scaling_get_resolution_pair(display: dict) -> tuple[dict | None, dict | None]:
    """Get default (more space) and scaled (larger text) mode pair."""
    model = scaling_get_model_identifier()
    if model in SCALING_MODEL_RESOLUTIONS:
        default_res, scaled_res = SCALING_MODEL_RESOLUTIONS[model]
        default_mode = scaling_find_mode_by_resolution(display, default_res)
        scaled_mode = scaling_find_mode_by_resolution(display, scaled_res)
        if default_mode and scaled_mode:
            return default_mode, scaled_mode

    modes = scaling_get_scaled_modes(display)
    if len(modes) < 2:
        return None, None
    return modes[0], modes[1]


def scaling_set_resolution(display: dict, mode: dict) -> bool:
    """Set display resolution using displayplacer."""
    screen_id = display.get("id")
    if not screen_id:
        print("Could not determine screen ID", file=sys.stderr)
        return False

    cmd = [
        "displayplacer",
        f"id:{screen_id} res:{mode['res']} hz:{mode['hz']} color_depth:{mode['color_depth']} scaling:on",
    ]

    try:
        subprocess.run(cmd, check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error setting resolution: {e}", file=sys.stderr)
        return False


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
            ["defaults", "write", "com.apple.dock", "autohide", "-bool", str(enabled).lower()],
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


def scaling_toggle() -> int:
    """Toggle display scaling."""
    display = scaling_get_builtin_display()
    if not display:
        print("Could not find built-in display", file=sys.stderr)
        return 1

    current = display.get("resolution")
    if not current:
        print("Could not determine current resolution", file=sys.stderr)
        return 1

    default_mode, scaled_mode = scaling_get_resolution_pair(display)
    if not default_mode or not scaled_mode:
        print("Could not find suitable resolution modes", file=sys.stderr)
        return 1

    if current == default_mode["res"]:
        if scaling_set_resolution(display, scaled_mode):
            print(f"Switched to larger text ({scaled_mode['res']})")
            return 0
    else:
        if scaling_set_resolution(display, default_mode):
            print(f"Switched to more space ({default_mode['res']})")
            return 0

    return 1


def cmd_scaling(args: argparse.Namespace) -> int:
    if not is_macos():
        print("Scaling settings only available on macOS", file=sys.stderr)
        return 1

    result = scaling_toggle()
    if result == 0 and args.dock:
        dock_toggle()
    return result


# Dock: Toggle dock autohide (macOS only)
def cmd_dock(args: argparse.Namespace) -> int:
    if not is_macos():
        print("Dock settings only available on macOS", file=sys.stderr)
        return 1

    if args.status:
        hidden = dock_get_autohide()
        status = "hidden (auto-hide enabled)" if hidden else "visible"
        print(f"Dock: {status}")
        return 0

    return dock_toggle()


# Autohide: Toggle dock and menubar autohide (macOS only)
def cmd_autohide(args: argparse.Namespace) -> int:
    if not is_macos():
        print("Autohide settings only available on macOS", file=sys.stderr)
        return 1

    if args.mode:
        # Explicit mode specified
        mode = args.mode
    else:
        # Toggle between always and fullscreen
        dock_hidden = dock_get_autohide()
        menubar_mode = menubar_get_current_mode()

        if dock_hidden or menubar_mode == "always":
            mode = "fullscreen"
        elif menubar_mode == "fullscreen":
            mode = "always"
        else:
            # Default to fullscreen for other modes (desktop, never)
            mode = "fullscreen"

    # Set dock based on mode
    if mode == "always":
        dock_set_autohide(True)
        print("Dock: hidden")
    else:
        dock_set_autohide(False)
        print("Dock: visible")

    menubar_set_mode(mode)
    print(f"Menubar: {MENUBAR_MODE_DESCRIPTIONS[mode]}")

    return 0


# Scrolling: Natural scrolling toggle (macOS only)
def scrolling_get_natural() -> bool:
    """Get current natural scrolling state using private framework."""
    from ctypes import cdll

    lib = cdll.LoadLibrary(
        "/System/Library/PrivateFrameworks/PreferencePanesSupport.framework/Versions/A/PreferencePanesSupport"
    )
    return lib.swipeScrollDirection() == 1


def scrolling_set_natural(enabled: bool) -> None:
    """Set natural scrolling state using private framework (takes effect immediately)."""
    from ctypes import cdll

    lib = cdll.LoadLibrary(
        "/System/Library/PrivateFrameworks/PreferencePanesSupport.framework/Versions/A/PreferencePanesSupport"
    )
    lib.setSwipeScrollDirection(1 if enabled else 0)


def cmd_scrolling(args: argparse.Namespace) -> int:
    if not is_macos():
        print("Scrolling settings only available on macOS", file=sys.stderr)
        return 1

    if args.status:
        natural = scrolling_get_natural()
        status = "natural" if natural else "traditional"
        print(f"Scrolling: {status}")
        return 0

    if args.mode:
        enabled = args.mode == "natural"
        scrolling_set_natural(enabled)
        status = "natural" if enabled else "traditional"
        print(f"Scrolling: {status}")
        return 0

    # Toggle
    current = scrolling_get_natural()
    scrolling_set_natural(not current)
    status = "traditional" if current else "natural"
    print(f"Scrolling: {status}")
    return 0


# Main CLI
def main() -> int:
    parser = argparse.ArgumentParser(
        description="Toggle system settings (appearance, menubar, scaling)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Appearance subcommand
    appearance_parser = subparsers.add_parser(
        "appearance",
        aliases=["a"],
        help="Toggle dark/light mode and wallpaper",
    )
    appearance_parser.add_argument(
        "--init",
        action="store_true",
        help="Initialize to dark mode without toggling",
    )
    appearance_parser.set_defaults(func=cmd_appearance)

    # Menubar subcommand
    menubar_parser = subparsers.add_parser(
        "menubar",
        aliases=["m"],
        help="Toggle menubar visibility (macOS only)",
    )
    menubar_parser.add_argument(
        "--status",
        action="store_true",
        help="Show current menubar mode",
    )
    menubar_parser.add_argument(
        "mode",
        nargs="?",
        choices=["always", "desktop", "fullscreen", "never"],
        help="Set specific mode (default: toggle fullscreen/desktop)",
    )
    menubar_parser.set_defaults(func=cmd_menubar)

    # Scaling subcommand
    scaling_parser = subparsers.add_parser(
        "scaling",
        aliases=["s", "scale"],
        help="Toggle display scaling (macOS only)",
    )
    scaling_parser.add_argument(
        "--dock",
        action="store_true",
        help="Also toggle dock auto-hide",
    )
    scaling_parser.set_defaults(func=cmd_scaling)

    # Dock subcommand
    dock_parser = subparsers.add_parser(
        "dock",
        aliases=["d"],
        help="Toggle dock autohide (macOS only)",
    )
    dock_parser.add_argument(
        "--status",
        action="store_true",
        help="Show current dock autohide status",
    )
    dock_parser.set_defaults(func=cmd_dock)

    # Autohide subcommand
    autohide_parser = subparsers.add_parser(
        "autohide",
        aliases=["ah"],
        help="Toggle dock and menubar autohide (macOS only)",
    )
    autohide_parser.add_argument(
        "mode",
        nargs="?",
        choices=["always", "desktop", "fullscreen", "never"],
        help="Set specific mode (default: toggle between always/fullscreen)",
    )
    autohide_parser.set_defaults(func=cmd_autohide)

    # Scrolling subcommand
    scrolling_parser = subparsers.add_parser(
        "scrolling",
        aliases=["scroll"],
        help="Toggle natural scrolling (macOS only)",
    )
    scrolling_parser.add_argument(
        "--status",
        action="store_true",
        help="Show current scrolling mode",
    )
    scrolling_parser.add_argument(
        "mode",
        nargs="?",
        choices=["natural", "traditional"],
        help="Set specific mode (default: toggle)",
    )
    scrolling_parser.set_defaults(func=cmd_scrolling)

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 0

    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
