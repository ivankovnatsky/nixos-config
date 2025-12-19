#!/usr/bin/env python3

import os
import subprocess
import sys
from datetime import date
from pathlib import Path
import platform


def is_macos() -> bool:
    return platform.system() == "Darwin"


def is_kde() -> bool:
    # Check environment variables first
    desktop = os.environ.get("XDG_CURRENT_DESKTOP", "")
    if "KDE" in desktop or "Plasma" in desktop:
        return True

    # Fallback: check if plasmashell is running
    try:
        subprocess.run(["pgrep", "plasmashell"], check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError:
        return False


# macOS Functions


def get_current_theme_macos() -> bool:
    """Returns True if dark mode is enabled."""
    result = subprocess.run(
        [
            "osascript",
            "-e",
            'tell application "System Events" to tell appearance preferences to get dark mode',
        ],
        capture_output=True,
        text=True,
    )
    return result.stdout.strip() == "true"


def set_dark_mode_macos(dark: bool) -> None:
    mode = "true" if dark else "false"
    subprocess.run(
        [
            "osascript",
            "-e",
            f'tell application "System Events" to tell appearance preferences to set dark mode to {mode}',
        ],
        check=True,
    )


def set_wallpaper_macos(color: str) -> None:
    file_path = f"/System/Library/Desktop Pictures/Solid Colors/{color}.png"
    script = f'''
tell application "System Events"
    tell every desktop
        set picture to "{file_path}"
    end tell
end tell
'''
    subprocess.run(["osascript", "-e", script], check=True)


def open_settings_macos() -> None:
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


# KDE Plasma Functions


def get_current_theme_kde() -> bool:
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


def set_theme_kde(dark: bool) -> None:
    scheme = "BreezeDark" if dark else "BreezeLight"
    subprocess.run(["plasma-apply-colorscheme", scheme], check=True)


def set_wallpaper_kde(color: str) -> None:
    rgb = "0,0,0" if color == "Black" else "192,192,192"  # Silver

    # Get all desktop IDs
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


def open_settings_kde() -> None:
    subprocess.Popen(["systemsettings", "appearance"])


# State management


def get_state_dir() -> Path:
    return Path.home() / ".local" / "state" / "switch-appearance"


def get_state_file() -> Path:
    return get_state_dir() / "last-run"


def write_state() -> None:
    state_dir = get_state_dir()
    state_dir.mkdir(parents=True, exist_ok=True)
    get_state_file().write_text(date.today().isoformat())


def remove_state() -> None:
    try:
        get_state_file().unlink()
    except FileNotFoundError:
        pass


# Platform-agnostic helpers


def set_dark_mode(dark: bool) -> None:
    if is_macos():
        set_dark_mode_macos(dark)
        color = "Black" if dark else "Silver"
        set_wallpaper_macos(color)
    elif is_kde():
        set_theme_kde(dark)
        color = "Black" if dark else "Silver"
        set_wallpaper_kde(color)
    else:
        raise RuntimeError("Unsupported platform")


def get_current_theme() -> bool:
    if is_macos():
        return get_current_theme_macos()
    elif is_kde():
        return get_current_theme_kde()
    else:
        raise RuntimeError("Unsupported platform")


def open_settings() -> None:
    if is_macos():
        open_settings_macos()
    elif is_kde():
        open_settings_kde()


def handle_init() -> None:
    if not is_macos() and not is_kde():
        raise RuntimeError("Unsupported platform")

    set_dark_mode(True)
    print("Set dark mode and wallpaper (init)")
    remove_state()


def handle_toggle() -> None:
    if not is_macos() and not is_kde():
        raise RuntimeError("Unsupported platform or desktop environment")

    is_dark = get_current_theme()

    # Toggle to opposite
    new_dark = not is_dark
    set_dark_mode(new_dark)

    if new_dark:
        print("Switched to Dark appearance")
    else:
        print("Switched to Light appearance")

    try:
        write_state()
    except Exception as e:
        print(f"Warning: could not write state: {e}", file=sys.stderr)

    try:
        open_settings()
    except Exception as e:
        print(f"Warning: could not open settings: {e}", file=sys.stderr)


def main() -> None:
    try:
        if len(sys.argv) > 1 and sys.argv[1] == "init":
            handle_init()
        else:
            handle_toggle()
    except Exception as e:
        print(str(e), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
