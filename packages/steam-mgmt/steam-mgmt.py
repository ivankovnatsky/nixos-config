#!/usr/bin/env python3

import argparse
import os
import shutil
import subprocess
import sys

STEAM_DIR = os.environ.get("STEAM_DIR", os.path.expanduser("~/.local/share/steam-servers"))
GAMES_DIR = os.path.join(STEAM_DIR, "games")


def run_steamcmd(*args):
    """Run steamcmd with the given arguments."""
    cmd = ["steamcmd"] + list(args) + ["+quit"]
    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        print("Error: steamcmd not found in PATH", file=sys.stderr)
        sys.exit(1)


def cmd_install(args):
    install_dir = args.directory or os.path.join(GAMES_DIR, args.app_id)
    os.makedirs(install_dir, exist_ok=True)
    print(f"Installing app {args.app_id} to {install_dir}...")
    run_steamcmd(
        "+force_install_dir", install_dir,
        "+login", "anonymous",
        "+app_update", args.app_id, "validate",
    )
    print(f"Done. Installed to {install_dir}")


def cmd_update(args):
    install_dir = args.directory or os.path.join(GAMES_DIR, args.app_id)
    if not os.path.isdir(install_dir):
        print(f"Error: {install_dir} does not exist. Install first.", file=sys.stderr)
        sys.exit(1)
    print(f"Updating app {args.app_id} in {install_dir}...")
    run_steamcmd(
        "+force_install_dir", install_dir,
        "+login", "anonymous",
        "+app_update", args.app_id,
    )
    print("Done.")


def cmd_validate(args):
    install_dir = args.directory or os.path.join(GAMES_DIR, args.app_id)
    if not os.path.isdir(install_dir):
        print(f"Error: {install_dir} does not exist. Install first.", file=sys.stderr)
        sys.exit(1)
    print(f"Validating app {args.app_id} in {install_dir}...")
    run_steamcmd(
        "+force_install_dir", install_dir,
        "+login", "anonymous",
        "+app_update", args.app_id, "validate",
    )
    print("Done.")


def cmd_remove(args):
    directory = os.path.realpath(args.directory)
    games_real = os.path.realpath(GAMES_DIR)
    if not directory.startswith(games_real + os.sep):
        print(f"Error: refusing to remove {directory} (not under {games_real})", file=sys.stderr)
        sys.exit(1)
    if not os.path.isdir(directory):
        print(f"Error: {directory} does not exist.", file=sys.stderr)
        sys.exit(1)
    answer = input(f"Remove {directory}? [y/N] ")
    if answer.lower() == "y":
        shutil.rmtree(directory)
        print(f"Removed {directory}")
    else:
        print("Cancelled.")


def cmd_list(args):
    os.makedirs(GAMES_DIR, exist_ok=True)
    entries = sorted(os.listdir(GAMES_DIR))
    if not entries:
        print(f"No games installed in {GAMES_DIR}")
        return
    print(f"Installed games in {GAMES_DIR}:")
    for name in entries:
        path = os.path.join(GAMES_DIR, name)
        if not os.path.isdir(path):
            continue
        result = subprocess.run(
            ["du", "-sh", path],
            capture_output=True, text=True,
        )
        size = result.stdout.split()[0] if result.stdout else "?"
        print(f"  {name} ({size})")


def cmd_info(args):
    run_steamcmd(
        "+login", "anonymous",
        "+app_info_print", args.app_id,
    )


def main():
    parser = argparse.ArgumentParser(description="Manage Steam game servers using steamcmd")
    subparsers = parser.add_subparsers(dest="command", required=True)

    p_install = subparsers.add_parser("install", help="Install a game/server by App ID")
    p_install.add_argument("app_id", help="Steam App ID")
    p_install.add_argument("directory", nargs="?", help="Install directory (default: ~/.steam/games/<app_id>)")
    p_install.set_defaults(func=cmd_install)

    p_update = subparsers.add_parser("update", help="Update an installed game/server")
    p_update.add_argument("app_id", help="Steam App ID")
    p_update.add_argument("directory", nargs="?", help="Install directory")
    p_update.set_defaults(func=cmd_update)

    p_validate = subparsers.add_parser("validate", help="Validate installed game files")
    p_validate.add_argument("app_id", help="Steam App ID")
    p_validate.add_argument("directory", nargs="?", help="Install directory")
    p_validate.set_defaults(func=cmd_validate)

    p_remove = subparsers.add_parser("remove", help="Remove an installed game directory")
    p_remove.add_argument("directory", help="Directory to remove")
    p_remove.set_defaults(func=cmd_remove)

    p_list = subparsers.add_parser("list", help="List installed games")
    p_list.set_defaults(func=cmd_list)

    p_info = subparsers.add_parser("info", help="Show app info via steamcmd")
    p_info.add_argument("app_id", help="Steam App ID")
    p_info.set_defaults(func=cmd_info)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
