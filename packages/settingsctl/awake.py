"""Awake: Prevent system from sleeping (macOS + Linux)."""

from __future__ import annotations

import shutil
import subprocess
import sys
import time

import click

from common import is_linux, is_macos

DEFAULT_TIMEOUT = 43200  # 12 hours in seconds


def awake_macos(
    display: bool,
    idle: bool,
    disk: bool,
    system: bool,
    user_active: bool,
    timeout: int | None,
    waitpid: int | None,
) -> int:
    """Prevent sleep on macOS using caffeinate(8)."""
    cmd: list[str] = ["/usr/bin/caffeinate"]
    if display:
        cmd.append("-d")
    if idle:
        cmd.append("-i")
    if disk:
        cmd.append("-m")
    if system:
        cmd.append("-s")
    if user_active:
        cmd.append("-u")
    if timeout is not None:
        cmd.extend(["-t", str(timeout)])
    if waitpid is not None:
        cmd.extend(["-w", str(waitpid)])
    print(f"Running: {' '.join(cmd)}")
    try:
        subprocess.run(cmd, check=True)
        return 0
    except KeyboardInterrupt:
        print("\nStopped")
        return 0
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


def awake_linux_systemd() -> int:
    """Prevent sleep on Linux using systemd-inhibit (indefinite)."""
    print("Preventing sleep on Linux (indefinite, Ctrl-C to stop)...")
    try:
        subprocess.run(
            [
                "systemd-inhibit",
                "--what=idle:sleep:handle-lid-switch",
                "--who=settings-awake",
                "--why=User requested to prevent sleep",
                "--mode=block",
                "sleep",
                "infinity",
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


def awake_linux_xset() -> int:
    """Prevent sleep on Linux using xset (X11, indefinite)."""
    print("Preventing sleep on Linux using xset (indefinite, Ctrl-C to stop)...")
    try:
        while True:
            subprocess.run(
                ["xset", "s", "off", "-dpms"], check=True, capture_output=True
            )
            time.sleep(60)
    except KeyboardInterrupt:
        print("\nStopped")
        return 0
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


def open_manpage() -> int:
    """Open caffeinate(8) man page."""
    try:
        return subprocess.run(["man", "caffeinate"]).returncode
    except FileNotFoundError:
        print("Error: 'man' not found", file=sys.stderr)
        return 1


def register(cli):
    @cli.command()
    @click.option(
        "--display",
        is_flag=True,
        help="Prevent the display from sleeping (caffeinate -d).",
    )
    @click.option(
        "--idle",
        is_flag=True,
        help="Prevent the system from idle sleeping (caffeinate -i).",
    )
    @click.option(
        "--disk",
        is_flag=True,
        help="Prevent the disk from idle sleeping (caffeinate -m).",
    )
    @click.option(
        "--system",
        "system_",
        is_flag=True,
        help="Prevent the system from sleeping; AC power only (caffeinate -s).",
    )
    @click.option(
        "--user-active",
        is_flag=True,
        help="Declare user is active; turns display on if off (caffeinate -u).",
    )
    @click.option(
        "--timeout",
        type=int,
        default=None,
        help=(
            "Timeout in seconds before the assertion is dropped (caffeinate -t). "
            f"Default when no flags are given: {DEFAULT_TIMEOUT} (12h)."
        ),
    )
    @click.option(
        "--waitpid",
        type=int,
        default=None,
        metavar="PID",
        help="Wait for process PID to exit, then release the assertion (caffeinate -w).",
    )
    @click.option(
        "--manpage",
        is_flag=True,
        help="Open caffeinate(8) man page and exit (macOS only).",
    )
    def awake(
        display: bool,
        idle: bool,
        disk: bool,
        system_: bool,
        user_active: bool,
        timeout: int | None,
        waitpid: int | None,
        manpage: bool,
    ):
        """Prevent system from sleeping (macOS + Linux).

        On macOS, options map directly to caffeinate(8) flags. With no
        options, defaults to --display --idle --disk --system --timeout=43200
        (stop all sleep activities for 12 hours).

        On Linux, all options are ignored — the command runs indefinitely
        until interrupted.
        """
        if manpage:
            if not is_macos():
                print(
                    "Error: --manpage is macOS-only (caffeinate is not available on this platform)",
                    file=sys.stderr,
                )
                sys.exit(1)
            sys.exit(open_manpage())

        if is_macos():
            no_flags = (
                not any(
                    [display, idle, disk, system_, user_active, waitpid is not None]
                )
                and timeout is None
            )
            if no_flags:
                display = idle = disk = system_ = True
                timeout = DEFAULT_TIMEOUT
            result = awake_macos(
                display, idle, disk, system_, user_active, timeout, waitpid
            )
        elif is_linux():
            if (
                any([display, idle, disk, system_, user_active, waitpid is not None])
                or timeout is not None
            ):
                print(
                    "Warning: caffeinate options are ignored on Linux; running indefinitely",
                    file=sys.stderr,
                )
            if shutil.which("systemd-inhibit"):
                result = awake_linux_systemd()
            elif shutil.which("xset"):
                result = awake_linux_xset()
            else:
                print(
                    "Error: Could not find systemd-inhibit or xset",
                    file=sys.stderr,
                )
                sys.exit(1)
        else:
            print("Unsupported platform", file=sys.stderr)
            sys.exit(1)

        if result != 0:
            sys.exit(result)
