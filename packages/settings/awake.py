"""Awake: Prevent system from sleeping (macOS + Linux)."""

from __future__ import annotations

import subprocess
import sys
import time

import click

from common import is_linux, is_macos

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
            self.fail(
                f"{value!r} is not a valid duration (e.g. 30m, 2h, 90s)", param, ctx
            )


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


def register(cli):
    @cli.command()
    @click.option(
        "-t",
        "--timeout",
        type=DURATION,
        default=DEFAULT_AWAKE_TIMEOUT,
        help=f"Timeout as duration, e.g. 30m, 2h, 90s (default: {DEFAULT_AWAKE_TIMEOUT} = 12 hours)",
    )
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
