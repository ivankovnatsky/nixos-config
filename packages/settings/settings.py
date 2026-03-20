#!/usr/bin/env python3
"""Unified settings tool for toggling system preferences.

Subcommands:
  appearance  Toggle dark/light mode and wallpaper (macOS + KDE)
  menubar     Toggle menubar visibility modes (macOS only)
  scaling     Toggle display scaling resolution (macOS only)
  scrolling   Toggle natural scrolling on/off (macOS only)
  location    Toggle Location Services on/off (macOS only)
  awake       Prevent system from sleeping (macOS + Linux)
  spaces      Add or remove desktop spaces (macOS only)
  windows     Close/hide app windows (macOS only)
  volume      Get or set system volume (macOS + Linux)
  accessibility Manage accessibility permissions (macOS only)
  login       List, add, or remove login items (macOS only)
  poweroff    Set volume and shutdown system (macOS + Linux)
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

import click

# Full path required because Homebrew PATH isn't available during Nix Darwin activation
DISPLAYPLACER_PATH = "/opt/homebrew/bin/displayplacer"
POWEROFF_VOLUME_SET = "1.0"

# Command aliases
COMMAND_ALIASES = {
    "a": "appearance",
    "m": "menubar",
    "s": "scaling",
    "scale": "scaling",
    "d": "dock",
    "ah": "autohide",
    "scroll": "scrolling",
    "loc": "location",
    "w": "awake",
    "sp": "spaces",
    "space": "spaces",
    "desktop": "spaces",
    "desktops": "spaces",
    "win": "windows",
    "vol": "volume",
    "v": "volume",
    "ac": "accessibility",
    "acc": "accessibility",
    "li": "login",
    "off": "poweroff",
    "h": "help",
}

# Build reverse mapping: command -> list of aliases
REVERSE_ALIASES: dict[str, list[str]] = {}
for _alias, _target in COMMAND_ALIASES.items():
    REVERSE_ALIASES.setdefault(_target, []).append(_alias)


class AliasedGroup(click.Group):
    def get_command(self, ctx, cmd_name):
        rv = click.Group.get_command(self, ctx, cmd_name)
        if rv is not None:
            return rv
        target = COMMAND_ALIASES.get(cmd_name)
        if target:
            return click.Group.get_command(self, ctx, target)
        return None

    def resolve_command(self, ctx, args):
        cmd_name = args[0] if args else None
        if cmd_name and cmd_name in COMMAND_ALIASES:
            args = [COMMAND_ALIASES[cmd_name]] + args[1:]
        return super().resolve_command(ctx, args)

    def format_commands(self, ctx, formatter):
        commands = []
        for subcommand in self.list_commands(ctx):
            cmd = self.commands.get(subcommand)
            if cmd is None or cmd.hidden:
                continue
            help_text = cmd.get_short_help_str(limit=150)
            aliases = REVERSE_ALIASES.get(subcommand, [])
            if aliases:
                display = f"{subcommand} ({','.join(sorted(aliases))})"
            else:
                display = subcommand
            commands.append((display, help_text))
        if commands:
            with formatter.section("Commands"):
                formatter.write_dl(commands)


@click.group(cls=AliasedGroup, invoke_without_command=True)
@click.pass_context
def cli(ctx):
    """Toggle system settings (appearance, menubar, scaling)"""
    if ctx.invoked_subcommand is None:
        click.echo(ctx.get_help())


# Platform Detection
def is_macos() -> bool:
    import platform

    return platform.system() == "Darwin"


def is_linux() -> bool:
    import platform

    return platform.system() == "Linux"


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


@cli.command()
@click.option("--init", is_flag=True, help="Initialize to dark mode without toggling")
def appearance(init):
    """Toggle dark/light mode and wallpaper"""
    if not is_macos() and not is_kde():
        print("Unsupported platform", file=sys.stderr)
        sys.exit(1)

    if init:
        state_file = appearance_get_state_file()
        today = date.today().isoformat()
        if state_file.exists() and state_file.read_text().strip() == today:
            print("Skipping appearance init (manual toggle was run today)")
            return
        appearance_set_dark_mode(True)
        print("Initialized appearance")
        appearance_remove_state()
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


# Menubar: Visibility Modes (macOS only)
# Maps mode name -> (defaults option value, UI description)
MENUBAR_MODES = {
    "never": (0, "Never"),
    "always": (1, "Always"),
    "fullscreen": (2, "In Full Screen Only"),
    "desktop": (3, "On Desktop Only"),
}

MENUBAR_OPTION_TO_MODE = {v[0]: k for k, v in MENUBAR_MODES.items()}


def menubar_get_current_mode() -> str:
    """Get current menubar visibility mode via defaults."""
    try:
        result = subprocess.run(
            ["defaults", "read", "com.apple.controlcenter", "AutoHideMenuBarOption"],
            capture_output=True,
            text=True,
        )
        option = int(result.stdout.strip())
        return MENUBAR_OPTION_TO_MODE.get(option, "unknown")
    except (subprocess.CalledProcessError, ValueError):
        return "unknown"


def menubar_get_description(mode: str) -> str:
    """Get human-readable description for a menubar mode."""
    return MENUBAR_MODES.get(mode, (None, "Unknown"))[1]


def menubar_set_mode(mode: str) -> None:
    """Set menubar visibility mode via osascript."""
    menu_item = menubar_get_description(mode)

    subprocess.run(
        [
            "open",
            "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension",
        ],
        check=True,
    )

    script = f"""
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
"""
    subprocess.run(["osascript", "-e", script], check=True)


def menubar_cycle_mode() -> None:
    """Toggle between fullscreen and desktop modes."""
    current = menubar_get_current_mode()

    if current == "fullscreen":
        next_mode = "desktop"
    else:
        next_mode = "fullscreen"

    menubar_set_mode(next_mode)
    print(f"Menubar: {menubar_get_description(next_mode)}")


@cli.command()
@click.option("--status", is_flag=True, help="Show current menubar mode")
@click.argument("mode", required=False, type=click.Choice(["always", "desktop", "fullscreen", "never"]))
def menubar(status, mode):
    """Toggle menubar visibility (macOS only)"""
    if not is_macos():
        print("Menubar settings only available on macOS", file=sys.stderr)
        sys.exit(1)

    if status:
        current = menubar_get_current_mode()
        desc = menubar_get_description(current)
        print(f"Current: {current} ({desc})")
        return

    if mode:
        if mode not in MENUBAR_MODES:
            print(f"Unknown mode: {mode}", file=sys.stderr)
            sys.exit(1)
        menubar_set_mode(mode)
        print(f"Menubar: {menubar_get_description(mode)}")
        return

    menubar_cycle_mode()


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
    if not os.path.exists(DISPLAYPLACER_PATH):
        return ""
    try:
        result = subprocess.run(
            [DISPLAYPLACER_PATH, "list"],
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


def scaling_get_current_display_args() -> list[str]:
    """Build displayplacer args for all displays with their current settings."""
    output = scaling_get_displayplacer_output()
    if not output:
        return []

    match = re.search(r'displayplacer\s+"([^"]+)"', output)
    if not match:
        match = re.findall(r'"(id:\S+[^"]*)"', output)
        if match:
            return list(match)
        return []

    args = [match.group(1)]
    for extra in re.findall(r'"(id:\S+[^"]*)"', output[match.end() :]):
        args.append(extra)
    return args


def scaling_set_resolution(display: dict, mode: dict) -> bool:
    """Set display resolution using displayplacer."""
    if not os.path.exists(DISPLAYPLACER_PATH):
        print("displayplacer not found", file=sys.stderr)
        return False

    screen_id = display.get("id")
    if not screen_id:
        print("Could not determine screen ID", file=sys.stderr)
        return False

    target_arg = f"id:{screen_id} res:{mode['res']} hz:{mode['hz']} color_depth:{mode['color_depth']} scaling:on"

    current_args = scaling_get_current_display_args()
    cmd = [DISPLAYPLACER_PATH]
    replaced = False
    for arg in current_args:
        if f"id:{screen_id}" in arg:
            cmd.append(target_arg)
            replaced = True
        else:
            cmd.append(arg)
    if not replaced:
        cmd.append(target_arg)

    try:
        subprocess.run(cmd, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
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
            [
                "defaults",
                "write",
                "com.apple.dock",
                "autohide",
                "-bool",
                str(enabled).lower(),
            ],
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


def scaling_get_current_mode_name(display: dict) -> str | None:
    """Get the current scaling mode name: 'scaled', 'default', or None."""
    current = display.get("resolution")
    if not current:
        return None

    default_mode, scaled_mode = scaling_get_resolution_pair(display)
    if not default_mode or not scaled_mode:
        return None

    if current == scaled_mode["res"]:
        return "scaled"
    elif current == default_mode["res"]:
        return "default"
    else:
        return None


def scaling_set_mode(mode: str) -> int:
    """Set display to specific scaling mode ('scaled' or 'default')."""
    display = scaling_get_builtin_display()
    if not display:
        print("Could not find built-in display", file=sys.stderr)
        return 1

    default_mode, scaled_mode = scaling_get_resolution_pair(display)
    if not default_mode or not scaled_mode:
        print("Could not find suitable resolution modes", file=sys.stderr)
        return 1

    current = display.get("resolution")

    if mode == "scaled":
        target_mode = scaled_mode
        label = "larger text"
    else:
        target_mode = default_mode
        label = "more space"

    if current == target_mode["res"]:
        print(f"Already at {label} ({target_mode['res']})")
        return 0

    if scaling_set_resolution(display, target_mode):
        print(f"Switched to {label} ({target_mode['res']})")
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


@cli.command()
@click.option("--status", is_flag=True, help="Show current scaling mode")
@click.option("--init", is_flag=True, help="Initialize to scaled mode (idempotent, for activation scripts)")
@click.option("--mode", type=click.Choice(["scaled", "default"]), help="Set specific mode: 'scaled' (larger text) or 'default' (more space)")
@click.option("--dock", "also_dock", is_flag=True, help="Also toggle dock auto-hide")
def scaling(status, init, mode, also_dock):
    """Toggle display scaling (macOS only)"""
    if not is_macos():
        print("Scaling settings only available on macOS", file=sys.stderr)
        sys.exit(1)

    if init:
        display = scaling_get_builtin_display()
        if not display:
            print("Skipping scaling init (no built-in display)")
            return
        mode_name = scaling_get_current_mode_name(display)
        if mode_name == "scaled":
            print("Skipping scaling init (already at scaled)")
            return
        result = scaling_set_mode("scaled")
        if result == 0:
            print("Initialized scaling to larger text")
        if result != 0:
            sys.exit(result)
        return

    if status:
        display = scaling_get_builtin_display()
        if not display:
            print("Could not find built-in display", file=sys.stderr)
            sys.exit(1)
        current = display.get("resolution")
        mode_name = scaling_get_current_mode_name(display)
        default_mode, scaled_mode = scaling_get_resolution_pair(display)
        if mode_name == "scaled":
            print(f"Scaling: larger text ({current})")
        elif mode_name == "default":
            print(f"Scaling: more space ({current})")
        else:
            print(f"Scaling: custom ({current})")
            if default_mode and scaled_mode:
                print(
                    f"  Available: more space ({default_mode['res']}), larger text ({scaled_mode['res']})"
                )
        return

    if mode:
        result = scaling_set_mode(mode)
    else:
        result = scaling_toggle()

    if result == 0 and also_dock:
        dock_toggle()
    if result != 0:
        sys.exit(result)


# Dock: Toggle dock autohide (macOS only)
@cli.command()
@click.option("--status", is_flag=True, help="Show current dock autohide status")
def dock(status):
    """Toggle dock autohide (macOS only)"""
    if not is_macos():
        print("Dock settings only available on macOS", file=sys.stderr)
        sys.exit(1)

    if status:
        hidden = dock_get_autohide()
        status_str = "hidden (auto-hide enabled)" if hidden else "visible"
        print(f"Dock: {status_str}")
        return

    result = dock_toggle()
    if result != 0:
        sys.exit(result)


# Autohide: Toggle dock and menubar autohide (macOS only)
@cli.command()
@click.option("--status", is_flag=True, help="Show current autohide status")
@click.argument("mode", required=False, type=click.Choice(["always", "desktop", "fullscreen", "never"]))
def autohide(status, mode):
    """Toggle dock and menubar autohide (macOS only)"""
    if not is_macos():
        print("Autohide settings only available on macOS", file=sys.stderr)
        sys.exit(1)

    if status:
        dock_hidden = dock_get_autohide()
        menubar_mode = menubar_get_current_mode()
        dock_status = "hidden (auto-hide enabled)" if dock_hidden else "visible"
        menubar_desc = menubar_get_description(menubar_mode)
        print(f"Dock: {dock_status}")
        print(f"Menubar: {menubar_mode} ({menubar_desc})")
        return

    if mode:
        target = mode
    else:
        # Toggle between always and fullscreen
        dock_hidden = dock_get_autohide()
        menubar_mode = menubar_get_current_mode()

        if dock_hidden or menubar_mode == "always":
            target = "fullscreen"
        elif menubar_mode == "fullscreen":
            target = "always"
        else:
            target = "fullscreen"

    # Set dock based on mode
    if target == "always":
        dock_set_autohide(True)
        print("Dock: hidden")
    else:
        dock_set_autohide(False)
        print("Dock: visible")

    menubar_set_mode(target)
    print(f"Menubar: {menubar_get_description(target)}")


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


@cli.command()
@click.option("--status", is_flag=True, help="Show current scrolling mode")
@click.argument("mode", required=False, type=click.Choice(["natural", "traditional"]))
def scrolling(status, mode):
    """Toggle natural scrolling (macOS only)"""
    if not is_macos():
        print("Scrolling settings only available on macOS", file=sys.stderr)
        sys.exit(1)

    if status:
        natural = scrolling_get_natural()
        status_str = "natural" if natural else "traditional"
        print(f"Scrolling: {status_str}")
        return

    if mode:
        enabled = mode == "natural"
        scrolling_set_natural(enabled)
        status_str = "natural" if enabled else "traditional"
        print(f"Scrolling: {status_str}")
        return

    # Toggle
    current = scrolling_get_natural()
    scrolling_set_natural(not current)
    status_str = "traditional" if current else "natural"
    print(f"Scrolling: {status_str}")


# Location: Toggle Location Services (macOS only)
LOCATION_SERVICES_URL = "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"


def location_check_enabled() -> bool | None:
    """Check Location Services status via CoreLocation (no UI, no sudo)."""
    try:
        result = subprocess.run(
            ["/usr/bin/swift", "-e", "import CoreLocation; print(CLLocationManager.locationServicesEnabled())"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0:
            return result.stdout.strip() == "true"
        return None
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None


def location_osascript(action: str) -> tuple[bool, int | None]:
    """Open Location Services pane and get/toggle the main switch.

    action: "toggle" to flip, "on" to enable, "off" to disable.
    Returns (success, value) where value is 0/1 or None on failure.
    """
    # Build the AppleScript action block
    if action == "on":
        action_block = """
                if value of firstCheckbox is 0 then
                    click firstCheckbox
                    delay 2
                end if
                return value of firstCheckbox"""
    elif action == "off":
        action_block = """
                if value of firstCheckbox is 1 then
                    click firstCheckbox
                    delay 2
                end if
                return value of firstCheckbox"""
    else:
        action_block = """
                click firstCheckbox
                delay 2
                return value of firstCheckbox"""

    script = f"""
tell application "System Settings" to quit
delay 0.5
do shell script "open '{LOCATION_SERVICES_URL}'"
delay 2
tell application "System Events"
    tell process "System Settings"
        set frontmost to true
        set allElements to entire contents of window 1
        repeat with el in allElements
            if class of el is checkbox then
                set firstCheckbox to el
                {action_block}
            end if
        end repeat
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
        # Close System Settings after
        subprocess.run(
            ["osascript", "-e", 'tell application "System Settings" to quit'],
            capture_output=True,
        )
        if result.returncode == 0:
            val = result.stdout.strip()
            if val in ("0", "1"):
                return True, int(val)
        return False, None
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
        subprocess.run(
            ["osascript", "-e", 'tell application "System Settings" to quit'],
            capture_output=True,
        )
        print(f"Error: {e}", file=sys.stderr)
        return False, None


@cli.command()
@click.option("--status", is_flag=True, help="Show current Location Services status")
@click.option("--init", is_flag=True, help="Enable Location Services if not already enabled (idempotent, for activation scripts)")
@click.argument("mode", required=False, type=click.Choice(["on", "off"]))
def location(status, init, mode):
    """Toggle Location Services (macOS only)"""
    if not is_macos():
        print("Location Services only available on macOS", file=sys.stderr)
        sys.exit(1)

    if status:
        enabled = location_check_enabled()
        if enabled is not None:
            status_str = "enabled" if enabled else "disabled"
            print(f"Location Services: {status_str}")
            return
        print("Could not read Location Services status", file=sys.stderr)
        sys.exit(1)

    if init:
        enabled = location_check_enabled()
        if enabled is True:
            print("Location Services: already enabled")
            return
        if enabled is None:
            print("Could not check Location Services status, skipping", file=sys.stderr)
            return
        print("Location Services is disabled. Enable manually: settings location on")
        return

    # Always check current state via Swift before touching UI
    enabled = location_check_enabled()
    if enabled is None:
        print("Could not read Location Services status", file=sys.stderr)
        sys.exit(1)

    if mode == "on" and enabled:
        print("Location Services: already enabled")
        return
    if mode == "off" and not enabled:
        print("Location Services: already disabled")
        return

    # Determine action: explicit mode or toggle
    if mode:
        action = mode
    else:
        action = "off" if enabled else "on"

    ok, val = location_osascript(action)
    if ok and val is not None:
        status_str = "enabled" if val == 1 else "disabled"
        print(f"Location Services: {status_str}")

        if val == 1 and not enabled:
            print("Opening Weather app to initialize location...")
            subprocess.run(["open", "-a", "Weather"], check=False)

        return

    print("Could not toggle Location Services (authentication may be required)", file=sys.stderr)
    sys.exit(1)


# Awake: Prevent system from sleeping (macOS + Linux)
DEFAULT_AWAKE_TIMEOUT = 43200  # 12 hours in seconds

DURATION_SUFFIXES = {"s": 1, "m": 60, "h": 3600, "d": 86400}


def parse_duration(value: str) -> int:
    """Parse duration string like '30m', '2h', '90s', or raw seconds."""
    value = value.strip()
    if value and value[-1].lower() in DURATION_SUFFIXES:
        try:
            return int(value[:-1]) * DURATION_SUFFIXES[value[-1].lower()]
        except ValueError:
            pass
    return int(value)


class DurationType(click.ParamType):
    name = "duration"

    def convert(self, value, param, ctx):
        if isinstance(value, int):
            return value
        try:
            return parse_duration(value)
        except (ValueError, TypeError):
            self.fail(f"{value!r} is not a valid duration (e.g. 30m, 2h, 90s)", param, ctx)


DURATION = DurationType()


def format_duration(seconds: int) -> str:
    """Format seconds into a human-readable duration string."""
    if seconds >= 86400 and seconds % 86400 == 0:
        return f"{seconds // 86400}d"
    if seconds >= 3600 and seconds % 3600 == 0:
        return f"{seconds // 3600}h"
    if seconds >= 60 and seconds % 60 == 0:
        return f"{seconds // 60}m"
    return f"{seconds}s"


def awake_macos(timeout: int) -> int:
    """Prevent sleep on macOS using caffeinate."""
    print(f"Preventing sleep on macOS for {format_duration(timeout)}...")
    try:
        subprocess.run(
            ["/usr/bin/caffeinate", "-d", "-i", "-m", "-s", "-t", str(timeout)],
            check=True,
        )
        return 0
    except KeyboardInterrupt:
        print("\nStopped")
        return 0
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


def awake_linux_systemd(timeout: int) -> int:
    """Prevent sleep on Linux using systemd-inhibit."""
    print(f"Preventing sleep on Linux for {format_duration(timeout)}...")
    try:
        subprocess.run(
            [
                "systemd-inhibit",
                "--what=idle:sleep:handle-lid-switch",
                "--who=settings-awake",
                "--why=User requested to prevent sleep",
                "--mode=block",
                "sleep",
                str(timeout),
            ],
            check=True,
        )
        return 0
    except KeyboardInterrupt:
        print("\nStopped")
        return 0
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


def awake_linux_xset(timeout: int) -> int:
    """Prevent sleep on Linux using xset (X11)."""
    print(f"Preventing sleep on Linux using xset for {format_duration(timeout)}...")
    import time

    start = time.time()
    try:
        while time.time() - start < timeout:
            subprocess.run(
                ["xset", "s", "off", "-dpms"], check=True, capture_output=True
            )
            time.sleep(60)
        return 0
    except KeyboardInterrupt:
        print("\nStopped")
        return 0
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


@cli.command()
@click.option("-t", "--timeout", type=DURATION, default=DEFAULT_AWAKE_TIMEOUT, help=f"Timeout as duration, e.g. 30m, 2h, 90s (default: {DEFAULT_AWAKE_TIMEOUT} = 12 hours)")
def awake(timeout):
    """Prevent system from sleeping (macOS + Linux)"""
    if is_macos():
        result = awake_macos(timeout)
    elif is_linux():
        r = subprocess.run(
            ["which", "systemd-inhibit"],
            capture_output=True,
        )
        if r.returncode == 0:
            result = awake_linux_systemd(timeout)
        else:
            r = subprocess.run(
                ["which", "xset"],
                capture_output=True,
            )
            if r.returncode == 0:
                result = awake_linux_xset(timeout)
            else:
                print("Error: Could not find systemd-inhibit or xset", file=sys.stderr)
                sys.exit(1)
    else:
        print("Unsupported platform", file=sys.stderr)
        sys.exit(1)

    if result != 0:
        sys.exit(result)


# Windows: Close/hide app windows (macOS only)
def windows_find_process(app_name: str) -> str | None:
    """Find exact process name matching case-insensitively."""
    script = """
tell application "System Events"
    get name of every process
end tell
"""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            check=True,
        )
        for name in result.stdout.strip().split(", "):
            if name.strip().lower() == app_name.lower():
                return name.strip()
        return None
    except subprocess.CalledProcessError:
        return None


def windows_close(app_name: str) -> bool:
    """Close all windows of an app using AppleScript.

    Activates the app first to bring windows from other Spaces,
    then closes all windows by clicking button 1 (close button),
    and finally hides the app so it doesn't stay in focus.
    App name matching is case-insensitive.
    """
    exact_name = windows_find_process(app_name)
    if not exact_name:
        return False

    script = f"""
tell application "System Events"
    tell application "{exact_name}" to activate
    delay 0.5
    tell process "{exact_name}"
        set windowCount to count of windows
        if windowCount > 0 then
            repeat with w in windows
                try
                    click button 1 of w
                end try
            end repeat
            delay 0.2
            set visible to false
            return "closed"
        else
            set visible to false
            return "no windows"
        end if
    end tell
end tell
"""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
        )
        return "closed" in result.stdout
    except subprocess.CalledProcessError:
        return False


def windows_hide(app_name: str) -> bool:
    """Hide an app (minimize all windows). Case-insensitive."""
    exact_name = windows_find_process(app_name)
    if not exact_name:
        return False

    script = f"""
tell application "System Events"
    set visible of process "{exact_name}" to false
    return "hidden"
end tell
"""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
        )
        return "hidden" in result.stdout
    except subprocess.CalledProcessError:
        return False


def windows_list() -> list[str]:
    """List apps with visible windows."""
    script = """
tell application "System Events"
    set visibleApps to {}
    repeat with p in (processes whose visible is true)
        set end of visibleApps to name of p
    end repeat
    return visibleApps
end tell
"""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            check=True,
        )
        apps = result.stdout.strip().split(", ")
        return [a.strip() for a in apps if a.strip()]
    except subprocess.CalledProcessError:
        return []


@cli.command()
@click.argument("action", type=click.Choice(["list", "close", "hide"]))
@click.argument("apps", nargs=-1)
def windows(action, apps):
    """Close/hide app windows (macOS only)"""
    if not is_macos():
        print("Windows management only available on macOS", file=sys.stderr)
        sys.exit(1)

    if action == "list":
        app_list = windows_list()
        if app_list:
            print("Apps with visible windows:")
            for app in app_list:
                print(f"  - {app}")
        else:
            print("No apps with visible windows")
        return

    if action == "close":
        if not apps:
            print("Error: app name(s) required for close action", file=sys.stderr)
            sys.exit(1)
        for app in apps:
            if windows_close(app):
                print(f"Closed windows of {app}")
            else:
                print(f"Could not close windows of {app} (not running or no windows)")
        return

    if action == "hide":
        if not apps:
            print("Error: app name(s) required for hide action", file=sys.stderr)
            sys.exit(1)
        for app in apps:
            if windows_hide(app):
                print(f"Hidden {app}")
            else:
                print(f"Could not hide {app} (not running)")
        return

    print("Unknown action", file=sys.stderr)
    sys.exit(1)


# Spaces: Add/remove desktop spaces (macOS only)
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
    import time

    for attempt in range(2):
        try:
            subprocess.run(["osascript", "-e", script], check=True)
            print(f"Removed desktop space {index}")
            return 0
        except subprocess.CalledProcessError as e:
            if attempt == 0:
                print(f"Space removal failed, retrying...", file=sys.stderr)
                time.sleep(1.0)
            else:
                print(f"Error removing space: {e}", file=sys.stderr)
                return 1
    return 1


@cli.command()
@click.argument("action", type=click.Choice(["add", "remove"]))
def spaces(action):
    """Add or remove desktop spaces (macOS only)"""
    if not is_macos():
        print("Spaces settings only available on macOS", file=sys.stderr)
        sys.exit(1)

    if action == "add":
        result = spaces_add()
    elif action == "remove":
        result = spaces_remove()
    else:
        print("Usage: settings spaces <add|remove>", file=sys.stderr)
        sys.exit(1)

    if result != 0:
        sys.exit(result)


# Volume: Get/set system volume (macOS + Linux)
def volume_get_macos() -> float | None:
    """Get current volume percentage on macOS using osascript."""
    try:
        result = subprocess.run(
            ["osascript", "-e", "output volume of (get volume settings)"],
            capture_output=True,
            text=True,
            check=True,
        )
        return float(result.stdout.strip())
    except (subprocess.CalledProcessError, FileNotFoundError, ValueError):
        return None


def volume_set_macos(percent: float) -> bool:
    """Set volume percentage on macOS using osascript."""
    try:
        # macOS volume is 0-100
        volume = int(round(percent))
        subprocess.run(
            ["osascript", "-e", f"set volume output volume {volume}"],
            check=True,
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error setting volume: {e}", file=sys.stderr)
        return False


def volume_get_linux() -> float | None:
    """Get current volume percentage on Linux using pactl."""
    try:
        result = subprocess.run(
            ["pactl", "get-sink-volume", "@DEFAULT_SINK@"],
            capture_output=True,
            text=True,
            check=True,
        )
        # Output format: "Volume: front-left: 65536 / 100% / 0.00 dB, ..."
        match = re.search(r"(\d+)%", result.stdout)
        if match:
            return float(match.group(1))
        return None
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def volume_set_linux(percent: float) -> bool:
    """Set volume percentage on Linux using pactl."""
    try:
        subprocess.run(
            ["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{percent:.1f}%"],
            check=True,
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error setting volume: {e}", file=sys.stderr)
        return False


def volume_get() -> float | None:
    """Get current volume percentage."""
    if is_macos():
        return volume_get_macos()
    elif is_linux():
        return volume_get_linux()
    else:
        print("Volume control only available on macOS and Linux", file=sys.stderr)
        return None


def volume_set(percent: float) -> bool:
    """Set volume percentage."""
    if is_macos():
        return volume_set_macos(percent)
    elif is_linux():
        return volume_set_linux(percent)
    else:
        print("Volume control only available on macOS and Linux", file=sys.stderr)
        return False


@cli.command()
@click.option("--status", is_flag=True, help="Show current volume level")
@click.argument("level", required=False, type=float)
def volume(status, level):
    """Get or set system volume (macOS + Linux)"""
    if not is_macos() and not is_linux():
        print("Volume settings only available on macOS and Linux", file=sys.stderr)
        sys.exit(1)

    if status:
        vol = volume_get()
        if vol is not None:
            print(f"Volume: {vol:.0f}%")
            return
        else:
            print("Could not get volume", file=sys.stderr)
            sys.exit(1)

    if level is not None:
        if volume_set(level):
            print(f"Volume: {level:.1f}%")
            return
        sys.exit(1)

    # Default: show status
    vol = volume_get()
    if vol is not None:
        print(f"Volume: {vol:.0f}%")
    else:
        print("Could not get volume", file=sys.stderr)
        sys.exit(1)


# Poweroff: Set volume and shutdown (macOS + Linux)
ICLOUD_SYNC_DELAY = 5  # seconds to wait for iCloud sync (file is < 1KB)


def poweroff_log_battery() -> None:
    """Log battery status to iCloud stats directory (macOS laptops only)."""
    if not is_macos():
        return

    import socket
    import time

    try:
        result = subprocess.run(
            ["pmset", "-g", "batt"],
            capture_output=True,
            text=True,
        )

        if "InternalBattery" not in result.stdout:
            return

        hostname = socket.gethostname()
        today = date.today().isoformat()
        stats_dir = (
            Path.home()
            / "Library/Mobile Documents/com~apple~CloudDocs/Data/Stats"
            / hostname
            / today
        )
        stats_dir.mkdir(parents=True, exist_ok=True)

        battery_file = stats_dir / "battery.txt"
        battery_file.write_text(result.stdout)
        print(f"Battery status logged to {battery_file}")

        # Wait for iCloud to sync (file is tiny, should be instant)
        print(f"Waiting {ICLOUD_SYNC_DELAY}s for iCloud sync...")
        time.sleep(ICLOUD_SYNC_DELAY)
    except Exception as e:
        print(f"Warning: Could not log battery status: {e}", file=sys.stderr)


def login_list() -> list[str]:
    script = 'tell application "System Events" to get the name of every login item'
    result = subprocess.run(
        ["osascript", "-e", script], capture_output=True, text=True
    )
    if result.returncode != 0:
        return []
    names = result.stdout.strip()
    if not names:
        return []
    return [n.strip() for n in names.split(",")]


def login_add(app_name: str) -> bool:
    app_path = f"/Applications/{app_name}.app"
    if not Path(app_path).exists():
        print(f"Error: {app_path} does not exist", file=sys.stderr)
        return False
    script = (
        f'tell application "System Events" to make login item at end '
        f'with properties {{path:"{app_path}", hidden:false}}'
    )
    result = subprocess.run(
        ["osascript", "-e", script], capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Error adding login item: {result.stderr.strip()}", file=sys.stderr)
        return False
    return True


def login_remove(item_name: str) -> bool:
    script = f'tell application "System Events" to delete login item "{item_name}"'
    result = subprocess.run(
        ["osascript", "-e", script], capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Error removing login item: {result.stderr.strip()}", file=sys.stderr)
        return False
    return True


@cli.command()
@click.argument("action", type=click.Choice(["list", "add", "remove"]))
@click.argument("apps", nargs=-1)
def login(action, apps):
    """List, add, or remove login items (macOS only)"""
    if not is_macos():
        print("Login items are only supported on macOS.", file=sys.stderr)
        sys.exit(1)

    if action == "list":
        items = login_list()
        if not items:
            print("No login items found.")
        else:
            for item in items:
                print(item)
        return

    if action == "add":
        if not apps:
            print("Error: specify app name(s) to add", file=sys.stderr)
            sys.exit(1)
        ok = True
        for app in apps:
            existing = login_list()
            if app in existing:
                print(f"Already a login item: {app}")
                continue
            if login_add(app):
                print(f"Added login item: {app}")
            else:
                ok = False
        if not ok:
            sys.exit(1)
        return

    if action == "remove":
        if not apps:
            print("Error: specify app name(s) to remove", file=sys.stderr)
            sys.exit(1)
        ok = True
        for app in apps:
            existing = login_list()
            if app not in existing:
                print(f"Not a login item: {app}")
                continue
            if login_remove(app):
                print(f"Removed login item: {app}")
            else:
                ok = False
        if not ok:
            sys.exit(1)
        return


@cli.command()
@click.option("-v", "--volume", "vol", type=float, default=POWEROFF_VOLUME_SET, help=f"Volume level before shutdown (default: {POWEROFF_VOLUME_SET}%)")
def poweroff(vol):
    """Set volume and shutdown system (macOS + Linux)"""
    if not is_macos() and not is_linux():
        print("Poweroff only available on macOS and Linux", file=sys.stderr)
        sys.exit(1)

    # Log battery status before shutdown (macOS only)
    poweroff_log_battery()

    # Set volume to specified level before shutdown
    if volume_set(vol):
        print(f"Volume set to {vol}%")
    else:
        print("Warning: Could not set volume", file=sys.stderr)

    # Shutdown the system
    print("Shutting down...")
    subprocess.run(["sudo", "shutdown", "-h", "now"], check=True)


# Accessibility: Manage accessibility permissions (macOS only)
ACCESSIBILITY_URL = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"


def accessibility_list() -> list[dict]:
    """List apps in Accessibility with their enabled status."""
    script = """
tell application "System Settings" to quit
delay 0.5
do shell script "open '""" + ACCESSIBILITY_URL + """'"
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
    return Path.home() / ".local" / "state" / "settings" / "accessibility-enabled"


def accessibility_state_matches(enable_apps: list[str]) -> bool:
    """Check if state file matches the requested app list."""
    state = accessibility_state_file()
    if not state.exists():
        return False
    return state.read_text().strip() == ",".join(sorted(enable_apps))


def accessibility_write_state(enable_apps: list[str]) -> None:
    state = accessibility_state_file()
    state.parent.mkdir(parents=True, exist_ok=True)
    state.write_text(",".join(sorted(enable_apps)))


def accessibility_enable(enable_apps: list[str]) -> None:
    """Ensure specified apps are enabled in Accessibility in a single UI session."""
    if accessibility_state_matches(enable_apps):
        print("Skipping accessibility enable (already configured)")
        return

    enable_checks = " or ".join(
        f'name of el is "{app}"' for app in enable_apps
    )
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
            print(f"Skipping accessibility init (could not read UI)", file=sys.stderr)
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


@cli.command()
@click.option("--enable", "enable_apps", help="Comma-separated list of apps to enable (idempotent)")
@click.argument("action", required=False, type=click.Choice(["list", "add", "remove", "toggle", "open"]))
@click.argument("app", required=False)
def accessibility(enable_apps, action, app):
    """Manage accessibility permissions (macOS only)"""
    if not is_macos():
        print("Accessibility settings only available on macOS", file=sys.stderr)
        sys.exit(1)

    if enable_apps:
        apps = [a.strip() for a in enable_apps.split(",")]
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
            print("Error: specify app path (e.g. /Applications/Amethyst.app)", file=sys.stderr)
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
            print(f"Could not add {app_path} (may need manual approval)", file=sys.stderr)
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


@cli.command("help", hidden=True)
@click.pass_context
def help_cmd(ctx):
    """Show this help message"""
    click.echo(ctx.parent.get_help())


# Main CLI
def main() -> int:
    cli(prog_name="settings")
    return 0


if __name__ == "__main__":
    sys.exit(main())
