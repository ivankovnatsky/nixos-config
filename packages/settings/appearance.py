"""Appearance: Dark/Light Mode + Wallpaper (macOS + KDE)."""

from __future__ import annotations

import subprocess
import sys
from datetime import date
from pathlib import Path

import click

from common import is_kde, is_macos


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
    script = f"""
tell application "System Events"
    tell every desktop
        set picture to "{file_path}"
    end tell
end tell
"""
    subprocess.run(["osascript", "-e", script], check=True)


def appearance_open_settings_macos() -> None:
    """Open Wallpaper settings and click 'Show on all Spaces' toggle."""
    script = """
tell application "System Settings"
    activate
    delay 0.5
    tell application "System Events"
        tell process "System Settings"
            click menu item "Wallpaper" of menu "View" of menu bar 1
            delay 0.5
            click checkbox "Show on all Spaces" of group 1 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of window 1
        end tell
    end tell
end tell
delay 0.2
tell application "System Settings" to quit
"""
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
    from common import _get_state_dir

    return _get_state_dir() / "appearance"


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


def register(cli):
    @cli.command()
    @click.option(
        "--init", is_flag=True, help="Initialize to dark mode without toggling"
    )
    def appearance(init):
        """Toggle dark/light mode and wallpaper"""
        if not is_macos() and not is_kde():
            print("Unsupported platform", file=sys.stderr)
            sys.exit(1)

        if init:
            appearance_get_state_dir().mkdir(parents=True, exist_ok=True)
            state_file = appearance_get_state_file()
            if state_file.exists():
                print("Skipping appearance init (already configured)")
                return
            appearance_set_dark_mode(True)
            print("Initialized appearance")
            appearance_write_state()
            return

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
