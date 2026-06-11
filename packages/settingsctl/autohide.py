"""Autohide: Toggle dock and menubar autohide (macOS only)."""

from __future__ import annotations

import sys

import click

from common import is_macos
from dock import dock_get_autohide, dock_set_autohide
from menubar import menubar_get_current_mode, menubar_get_description, menubar_set_mode


def register(cli):
    @cli.command()
    @click.option("--status", is_flag=True, help="Show current autohide status")
    @click.argument(
        "mode",
        required=False,
        type=click.Choice(["always", "desktop", "fullscreen", "never"]),
    )
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
