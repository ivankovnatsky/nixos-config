"""Scrolling: Natural scrolling toggle (macOS only)."""

from __future__ import annotations

import sys

import click

from common import is_macos


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


def register(cli):
    @cli.command()
    @click.option("--status", is_flag=True, help="Show current scrolling mode")
    @click.argument(
        "mode", required=False, type=click.Choice(["natural", "traditional"])
    )
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
