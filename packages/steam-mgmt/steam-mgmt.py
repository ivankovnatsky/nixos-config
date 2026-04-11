#!/usr/bin/env python3

import json
import os
import shutil
import subprocess
import sys

import click

STEAM_DIR = os.environ.get(
    "STEAM_DIR", os.path.expanduser("~/.local/share/steam-servers")
)
GAMES_DIR = os.path.join(STEAM_DIR, "games")
STATE_DIR = os.path.expanduser("~/.local/state/steam-mgmt")
MANIFEST_PATH = os.path.join(STATE_DIR, "games.json")
SOPS_DIR = os.path.expanduser("~/.config/sops-nix/secrets")


def read_secret(name):
    """Read a sops-nix decrypted secret by name."""
    path = os.path.join(SOPS_DIR, name)
    try:
        with open(path) as f:
            return f.read().strip()
    except (FileNotFoundError, PermissionError):
        return None


def get_login_args(user):
    """Return login arguments for steamcmd (no password in args)."""
    if user:
        return ["+login", user]
    username = read_secret("steam-username")
    if username:
        return ["+login", username]
    return ["+login", "anonymous"]


def get_password_path():
    """Return path to sops password file, or None."""
    path = os.path.join(SOPS_DIR, "steam-password")
    if os.path.isfile(path):
        return path
    return None


def run_steamcmd(*args):
    """Run steamcmd with the given arguments.

    Password is injected via shell using cat on the sops secret file,
    so it never appears in argv or logs.
    """
    # Check if login args need a password injected
    str_args = list(args)
    password_path = get_password_path()

    if password_path and "+login" in str_args:
        login_idx = str_args.index("+login")
        username_idx = login_idx + 1
        if username_idx < len(str_args) and str_args[username_idx] != "anonymous":
            # Build shell command: inject password from file via cat
            username = str_args[username_idx]
            before = str_args[:login_idx]
            after = str_args[username_idx + 1 :]
            shell_cmd = "steamcmd"
            for a in before:
                shell_cmd += f" '{a}'"
            shell_cmd += f" +login '{username}' \"$(cat '{password_path}')\""
            for a in after:
                shell_cmd += f" '{a}'"
            shell_cmd += " +quit"
            result = subprocess.run(shell_cmd, shell=True)
            if result.returncode != 0:
                click.echo(f"steamcmd exited with code {result.returncode}", err=True)
                sys.exit(1)
            return

    cmd = ["steamcmd"] + str_args + ["+quit"]
    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        click.echo("Error: steamcmd not found in PATH", err=True)
        sys.exit(1)


@click.group()
def cli():
    """Manage Steam games using steamcmd."""


@cli.command()
@click.argument("app_id")
@click.argument("directory", required=False)
@click.option("-u", "--user", help="Steam username (default: anonymous)")
def install(app_id, directory, user):
    """Install a game/server by App ID."""
    install_dir = directory or os.path.join(GAMES_DIR, app_id)
    os.makedirs(install_dir, exist_ok=True)
    login_args = get_login_args(user)
    click.echo(f"Installing app {app_id} to {install_dir}...")
    run_steamcmd(
        "+force_install_dir",
        install_dir,
        *login_args,
        "+app_update",
        app_id,
        "validate",
    )
    click.echo(f"Done. Installed to {install_dir}")


@cli.command()
@click.argument("app_id")
@click.argument("directory", required=False)
@click.option("-u", "--user", help="Steam username (default: anonymous)")
def update(app_id, directory, user):
    """Update an installed game/server."""
    install_dir = directory or os.path.join(GAMES_DIR, app_id)
    if not os.path.isdir(install_dir):
        click.echo(f"Error: {install_dir} does not exist. Install first.", err=True)
        sys.exit(1)
    login_args = get_login_args(user)
    click.echo(f"Updating app {app_id} in {install_dir}...")
    run_steamcmd(
        "+force_install_dir",
        install_dir,
        *login_args,
        "+app_update",
        app_id,
    )
    click.echo("Done.")


@cli.command()
@click.argument("app_id")
@click.argument("directory", required=False)
@click.option("-u", "--user", help="Steam username (default: anonymous)")
def validate(app_id, directory, user):
    """Validate installed game files."""
    install_dir = directory or os.path.join(GAMES_DIR, app_id)
    if not os.path.isdir(install_dir):
        click.echo(f"Error: {install_dir} does not exist. Install first.", err=True)
        sys.exit(1)
    login_args = get_login_args(user)
    click.echo(f"Validating app {app_id} in {install_dir}...")
    run_steamcmd(
        "+force_install_dir",
        install_dir,
        *login_args,
        "+app_update",
        app_id,
        "validate",
    )
    click.echo("Done.")


@cli.command()
@click.argument("directory")
@click.confirmation_option(prompt="Are you sure you want to remove this?")
def remove(directory):
    """Remove an installed game directory."""
    directory = os.path.realpath(directory)
    games_real = os.path.realpath(GAMES_DIR)
    if not directory.startswith(games_real + os.sep):
        click.echo(
            f"Error: refusing to remove {directory} (not under {games_real})", err=True
        )
        sys.exit(1)
    if not os.path.isdir(directory):
        click.echo(f"Error: {directory} does not exist.", err=True)
        sys.exit(1)
    shutil.rmtree(directory)
    click.echo(f"Removed {directory}")


@cli.command("list")
def list_games():
    """List installed games."""
    os.makedirs(GAMES_DIR, exist_ok=True)
    entries = sorted(os.listdir(GAMES_DIR))
    if not entries:
        click.echo(f"No games installed in {GAMES_DIR}")
        return
    click.echo(f"Installed games in {GAMES_DIR}:")
    for name in entries:
        path = os.path.join(GAMES_DIR, name)
        if not os.path.isdir(path):
            continue
        result = subprocess.run(
            ["du", "-sh", path],
            capture_output=True,
            text=True,
        )
        size = result.stdout.split()[0] if result.stdout else "?"
        click.echo(f"  {name} ({size})")


@cli.command()
@click.argument("app_id")
@click.option("-u", "--user", help="Steam username (default: anonymous)")
def info(app_id, user):
    """Show app info via steamcmd."""
    login_args = get_login_args(user)
    run_steamcmd(
        *login_args,
        "+app_info_print",
        app_id,
    )


@cli.command()
@click.option(
    "--dry-run", is_flag=True, help="Show what would be done without doing it"
)
@click.option("-y", "--yes", is_flag=True, help="Skip confirmation prompts")
@click.option("-u", "--user", help="Steam username (default: anonymous)")
def sync(dry_run, yes, user):
    """Sync installed games with declarative manifest."""
    if not os.path.isfile(MANIFEST_PATH):
        click.echo(f"Error: manifest not found at {MANIFEST_PATH}", err=True)
        click.echo("Run `nixos-rebuild` to generate it from steam-games.nix", err=True)
        sys.exit(1)

    with open(MANIFEST_PATH) as f:
        games = json.load(f)

    os.makedirs(GAMES_DIR, exist_ok=True)
    declared = {g["appId"] for g in games}

    # Only consider directories with actual content as installed
    installed = set()
    for name in os.listdir(GAMES_DIR):
        path = os.path.join(GAMES_DIR, name)
        if os.path.isdir(path) and os.listdir(path):
            installed.add(name)

    to_install = [g for g in games if g["appId"] not in installed]
    to_remove = [a for a in installed if a not in declared]

    if not to_install and not to_remove:
        click.echo("Everything in sync.")
        return

    if to_install:
        click.echo("To install:")
        for g in to_install:
            login = "anonymous" if g.get("anonymous", False) else "authenticated"
            click.echo(f"  {g['appId']}  {g['name']}  ({login})")

    if to_remove:
        click.echo("To remove:")
        for app_id in to_remove:
            click.echo(f"  {app_id}")

    if dry_run:
        return

    # Batch install: group by login type to minimize steamcmd sessions
    anon_games = [g for g in to_install if g.get("anonymous", False)]
    auth_games = [g for g in to_install if not g.get("anonymous", False)]

    if anon_games:
        batch_args = ["+login", "anonymous"]
        for game in anon_games:
            install_dir = os.path.join(GAMES_DIR, game["appId"])
            batch_args += [
                "+force_install_dir",
                install_dir,
                "+app_update",
                game["appId"],
                "validate",
            ]
        click.echo()
        click.echo(f"Installing {len(anon_games)} anonymous game(s)...")
        run_steamcmd(*batch_args)

    if auth_games:
        login_args = get_login_args(user)
        batch_args = list(login_args)
        for game in auth_games:
            install_dir = os.path.join(GAMES_DIR, game["appId"])
            batch_args += [
                "+force_install_dir",
                install_dir,
                "+app_update",
                game["appId"],
                "validate",
            ]
        click.echo()
        click.echo(f"Installing {len(auth_games)} authenticated game(s)...")
        run_steamcmd(*batch_args)

    if to_remove:
        if not yes:
            click.confirm(f"Remove {len(to_remove)} undeclared game(s)?", abort=True)
        for app_id in to_remove:
            path = os.path.join(GAMES_DIR, app_id)
            shutil.rmtree(path)
            click.echo(f"Removed {app_id}")

    click.echo()
    click.echo("Sync complete.")


if __name__ == "__main__":
    cli()
