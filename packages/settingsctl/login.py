"""Login: List, add, or remove login items (macOS only)."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import click

from common import _get_state_dir, is_macos, quit_app


def login_state_file() -> Path:
    return _get_state_dir() / "login-items"


def login_state_matches(app_list: list[str]) -> bool:
    state = login_state_file()
    if not state.exists():
        return False
    return state.read_text().strip() == ",".join(sorted(app_list))


def login_write_state(app_list: list[str]) -> None:
    login_state_file().write_text(",".join(sorted(app_list)))


def login_list_status() -> tuple[bool, list[str]]:
    """Returns (ok, items). ok is False if osascript itself failed."""
    script = 'tell application "System Events" to get the name of every login item'
    result = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
    if result.returncode != 0:
        return False, []
    names = result.stdout.strip()
    if not names:
        return True, []
    return True, [n.strip() for n in names.split(",")]


def login_list() -> list[str]:
    _, items = login_list_status()
    return items


def login_add(app_name: str) -> bool:
    app_path = f"/Applications/{app_name}.app"
    if not Path(app_path).exists():
        print(f"Error: {app_path} does not exist", file=sys.stderr)
        return False
    script = (
        f'tell application "System Events" to make login item at end '
        f'with properties {{path:"{app_path}", hidden:false}}'
    )
    result = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error adding login item: {result.stderr.strip()}", file=sys.stderr)
        return False
    return True


def login_remove(item_name: str) -> bool:
    script = f'tell application "System Events" to delete login item "{item_name}"'
    result = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error removing login item: {result.stderr.strip()}", file=sys.stderr)
        return False
    return True


def login_set(target_apps: list[str]) -> bool:
    """Sync login items to exactly target_apps (declarative).

    Diffs against the actual current login items every run, so items
    added outside our management (e.g. by an app's own installer) are
    removed too, not just ones we previously added ourselves.
    """
    ok_list, current_list = login_list_status()
    if not ok_list:
        print("Error: could not read current login items, skipping login set", file=sys.stderr)
        return False

    current = set(current_list)
    target = set(target_apps)

    to_remove = current - target
    to_add = target - current

    if not to_remove and not to_add:
        print("Skipping login set (already configured)")
        return True

    ok = True
    for app in sorted(to_remove):
        if login_remove(app):
            print(f"Removed login item: {app}")
            if quit_app(app):
                print(f"Quit running app: {app}")
        else:
            ok = False
    for app in sorted(to_add):
        if login_add(app):
            print(f"Added login item: {app}")
        else:
            ok = False
    try:
        login_write_state(target_apps)
    except Exception as e:
        print(f"Warning: could not write state: {e}", file=sys.stderr)
    return ok


def register(cli):
    @cli.command()
    @click.argument("action", type=click.Choice(["list", "add", "remove", "set"]))
    @click.argument("apps", required=False)
    def login(action, apps):
        """List, add, remove, or set login items (macOS only)

        APPS is a single app name or comma-separated list (e.g. "Amethyst,Hammerspoon,Mac Mouse Fix").

        The "set" action declaratively syncs login items to the provided list:
        items previously managed by us but no longer in the list are removed.
        """
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

        app_list = [a.strip() for a in apps.split(",")] if apps else []

        if action == "add":
            if not app_list:
                print("Error: specify app name(s) to add", file=sys.stderr)
                sys.exit(1)
            if login_state_matches(app_list):
                print("Skipping login add (already configured)")
                return
            ok = True
            for app in app_list:
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
            try:
                login_write_state(app_list)
            except Exception as e:
                print(f"Warning: could not write state: {e}", file=sys.stderr)
            return

        if action == "remove":
            if not app_list:
                print("Error: specify app name(s) to remove", file=sys.stderr)
                sys.exit(1)
            ok = True
            for app in app_list:
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

        if action == "set":
            if apps is None:
                print(
                    "Error: specify app list (use empty string for none)",
                    file=sys.stderr,
                )
                sys.exit(1)
            if not login_set(app_list):
                sys.exit(1)
            return
