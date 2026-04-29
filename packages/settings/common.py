"""Shared utilities: AliasedGroup, constants, platform detection, state helpers."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

import click

# Ensure system binaries are available during Nix activation
os.environ["PATH"] = "/usr/bin:/bin:/usr/sbin:" + os.environ.get("PATH", "")
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
    "fda": "fulldiskaccess",
    "fd": "fulldiskaccess",
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


def quit_app(app_name: str) -> bool:
    """Quit a running macOS app by name. Returns True if quit (or not running)."""
    script = f'tell application "{app_name}" to quit'
    result = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
    return result.returncode == 0


def _get_state_dir() -> Path:
    """Return persistent state directory (~/.local/state/settings/).

    When running under sudo (e.g. nix-darwin activation), Path.home()
    resolves to /var/root/ which is wrong.  Use SUDO_USER to find the
    real user's home so that state files are shared between interactive
    and activation contexts.
    """
    sudo_user = os.environ.get("SUDO_USER")
    if sudo_user:
        import pwd

        home = Path(pwd.getpwnam(sudo_user).pw_dir)
    else:
        home = Path.home()
    d = home / ".local" / "state" / "settings"
    d.mkdir(parents=True, exist_ok=True)
    return d
