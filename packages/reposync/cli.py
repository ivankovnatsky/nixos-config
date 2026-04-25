"""CLI argument parsing and subcommand dispatch."""

import re
import subprocess
import sys
import time
from pathlib import Path

import click

from config import get_discord_webhook, load_config
from repo import init_repo, needs_init, status_repo, sync_repo

BOOT_DEBOUNCE_SECONDS = 2 * 60


@click.group()
def main():
    """Sync local git repos with remotes."""


@main.command()
@click.option("--config-file", required=True)
def init(config_file):
    config = load_config(config_file)
    webhook_url = get_discord_webhook(config)
    all_ok = True
    for repo in config.get("repositories", []):
        if not init_repo(repo, webhook_url):
            all_ok = False
    sys.exit(0 if all_ok else 1)


def get_system_uptime():
    """Return system uptime in seconds on supported platforms."""
    if sys.platform.startswith("linux"):
        proc_uptime = Path("/proc/uptime")
        try:
            return float(proc_uptime.read_text().split()[0])
        except (IndexError, OSError, ValueError):
            return None

    if sys.platform != "darwin":
        return None

    result = subprocess.run(
        ["sysctl", "-n", "kern.boottime"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return None

    match = re.search(r"sec = (\d+)", result.stdout)
    if not match:
        return None

    return max(0, time.time() - int(match.group(1)))


def debounce_after_boot():
    uptime = get_system_uptime()
    if uptime is None or uptime >= BOOT_DEBOUNCE_SECONDS:
        return

    delay = BOOT_DEBOUNCE_SECONDS - uptime
    click.echo(
        f"System booted {uptime:.0f}s ago; delaying reposync for {delay:.0f}s.",
        err=True,
    )
    time.sleep(delay)


@main.command()
@click.option("--config-file", required=True)
def sync(config_file):
    config = load_config(config_file)
    webhook_url = get_discord_webhook(config)

    debounce_after_boot()

    # Only init repos that need it
    failed_paths = set()
    for repo in config.get("repositories", []):
        if needs_init(repo):
            if not init_repo(repo, webhook_url):
                failed_paths.add(repo["path"])

    # Then sync (skip repos whose init failed)
    all_ok = not failed_paths
    for repo in config.get("repositories", []):
        if repo["path"] in failed_paths:
            continue
        if not sync_repo(repo, webhook_url):
            all_ok = False
    sys.exit(0 if all_ok else 1)


@main.command()
@click.option("--config-file", required=True)
def status(config_file):
    config = load_config(config_file)
    for repo in config.get("repositories", []):
        status_repo(repo)
    sys.exit(0)
