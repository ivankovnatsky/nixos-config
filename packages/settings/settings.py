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
  windows     Close/hide/open/restart app windows (macOS only)
  volume      Get or set system volume (macOS + Linux)
  accessibility Manage accessibility permissions (macOS only)
  fulldiskaccess Manage Full Disk Access permissions (macOS only)
  login       List, add, or remove login items (macOS only)
  poweroff    Set volume and shutdown system (macOS + Linux)
  battery     Show battery state (macOS + Linux)
"""


import click

from common import AliasedGroup

import accessibility
import appearance
import autohide
import awake
import battery
import dock
import fulldiskaccess
import location
import login
import menubar
import poweroff
import scaling
import scrolling
import spaces
import volume
import windows


@click.group(cls=AliasedGroup, invoke_without_command=True)
@click.pass_context
def cli(ctx):
    """Toggle system settings (appearance, menubar, scaling)"""
    if ctx.invoked_subcommand is None:
        click.echo(ctx.get_help())


# Register all subcommands
accessibility.register(cli)
appearance.register(cli)
autohide.register(cli)
awake.register(cli)
battery.register(cli)
dock.register(cli)
fulldiskaccess.register(cli)
location.register(cli)
login.register(cli)
menubar.register(cli)
poweroff.register(cli)
scaling.register(cli)
scrolling.register(cli)
spaces.register(cli)
volume.register(cli)
windows.register(cli)


@cli.command("help", hidden=True)
@click.pass_context
def help_cmd(ctx):
    """Show this help message"""
    click.echo(ctx.parent.get_help())


if __name__ == "__main__":
    cli(prog_name="settings")
