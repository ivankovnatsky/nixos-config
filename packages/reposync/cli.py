"""CLI argument parsing and subcommand dispatch."""

import sys

import click

from config import get_discord_webhook, load_config
from repo import init_repo, needs_init, status_repo, sync_repo


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


@main.command()
@click.option("--config-file", required=True)
def sync(config_file):
    config = load_config(config_file)
    webhook_url = get_discord_webhook(config)

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
