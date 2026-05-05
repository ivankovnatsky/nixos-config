"""Scaling: Display Resolution (macOS only)."""

from __future__ import annotations

import sys

import click

from common import is_macos
from dock import dock_toggle
from scaling_displays import (
    scaling_get_builtin_display,
    scaling_get_current_mode_name,
    scaling_get_resolution_pair,
    scaling_set_resolution,
)


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


def register(cli):
    @cli.command()
    @click.option("--status", is_flag=True, help="Show current scaling mode")
    @click.option(
        "--init",
        is_flag=True,
        help="Initialize to scaled mode (idempotent, for activation scripts)",
    )
    @click.option(
        "--mode",
        type=click.Choice(["scaled", "default"]),
        help="Set specific mode: 'scaled' (larger text) or 'default' (more space)",
    )
    @click.option(
        "--dock", "also_dock", is_flag=True, help="Also toggle dock auto-hide"
    )
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
