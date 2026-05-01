"""Awake: Prevent system from sleeping (macOS + Linux)."""

from __future__ import annotations

import subprocess
import sys
import time

import click

from common import is_linux, is_macos


def awake_macos(args: list[str]) -> int:
    """Prevent sleep on macOS using caffeinate."""
    cmd = ["/usr/bin/caffeinate", *args]
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


def register(cli):
    @cli.command(
        context_settings={"ignore_unknown_options": True, "allow_extra_args": True}
    )
    @click.argument("args", nargs=-1, type=click.UNPROCESSED)
    def awake(args):
        """Prevent system from sleeping (macOS + Linux).

        On macOS, args are passed directly to caffeinate(8); run with no
        args to invoke caffeinate with its defaults.
        On Linux, args are not supported — the command always runs
        indefinitely until interrupted.
        """
        if is_macos():
            result = awake_macos(list(args))
        elif is_linux():
            if args:
                print(
                    f"Warning: ignoring args {list(args)} (not supported on Linux)",
                    file=sys.stderr,
                )
            r = subprocess.run(
                ["which", "systemd-inhibit"],
                capture_output=True,
            )
            if r.returncode == 0:
                result = awake_linux_systemd()
            else:
                r = subprocess.run(
                    ["which", "xset"],
                    capture_output=True,
                )
                if r.returncode == 0:
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
