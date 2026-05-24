"""Appearance: Dark/Light Mode + Wallpaper (macOS + KDE)."""

from __future__ import annotations

import os
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


def _kde_session_env() -> dict[str, str]:
    # plasma-apply-colorscheme shells out to xrdb internally; from a tmux/SSH
    # context XAUTHORITY is often stale or unset, so xrdb prints auth errors
    # even though the colorscheme switch itself succeeds. Pull the live values
    # from the running plasmashell process.
    env = os.environ.copy()
    try:
        pid = subprocess.check_output(
            ["pgrep", "-u", str(os.getuid()), "-x", "plasmashell"], text=True
        ).split()[0]
        with open(f"/proc/{pid}/environ", "rb") as f:
            raw = f.read().decode("utf-8", "replace")
        plasma_env = dict(item.split("=", 1) for item in raw.split("\0") if "=" in item)
        for key in (
            "DISPLAY",
            "XAUTHORITY",
            "WAYLAND_DISPLAY",
            "DBUS_SESSION_BUS_ADDRESS",
            "XDG_RUNTIME_DIR",
        ):
            if key in plasma_env:
                env[key] = plasma_env[key]
    except (subprocess.CalledProcessError, OSError, IndexError):
        pass
    return env


def appearance_set_theme_kde(dark: bool) -> None:
    scheme = "BreezeDark" if dark else "BreezeLight"
    subprocess.run(
        ["plasma-apply-colorscheme", scheme], check=True, env=_kde_session_env()
    )


def appearance_set_wallpaper_kde(hex_color: str) -> None:
    import dbus

    try:
        bus = dbus.SessionBus()
        proxy = bus.get_object("org.kde.plasmashell", "/PlasmaShell")
        iface = dbus.Interface(proxy, "org.kde.PlasmaShell")
        list_script = """
var screens = [];
var d = desktops();
for (var i = 0; i < d.length; i++) screens.push(d[i].screen);
print(screens.join(','));
"""
        raw = str(iface.evaluateScript(list_script)).strip()
        screens = [int(s) for s in raw.split(",") if s] or [0]
        for screen in screens:
            iface.setWallpaper(
                "org.kde.color", {"Color": hex_color}, dbus.UInt32(screen)
            )
    except dbus.DBusException as e:
        print(f"Warning: could not set KDE wallpaper: {e}", file=sys.stderr)


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
        hex_color = "#000000" if dark else "#ede9e9"
        appearance_set_wallpaper_kde(hex_color)
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
