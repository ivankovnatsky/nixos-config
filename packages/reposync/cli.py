"""CLI argument parsing and subcommand dispatch."""

import argparse
import sys

from config import get_discord_webhook, load_config
from repo import init_repo, needs_init, status_repo, sync_repo


def cmd_init(args):
    config = load_config(args.config_file)
    webhook_url = get_discord_webhook(config)
    all_ok = True
    for repo in config.get("repositories", []):
        if not init_repo(repo, webhook_url):
            all_ok = False
    return 0 if all_ok else 1


def cmd_sync(args):
    config = load_config(args.config_file)
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
    return 0 if all_ok else 1


def cmd_status(args):
    config = load_config(args.config_file)
    for repo in config.get("repositories", []):
        status_repo(repo)
    return 0


def main():
    parser = argparse.ArgumentParser(description="Sync local git repos with remotes")
    subparsers = parser.add_subparsers(dest="command", required=True)

    for name in ("init", "sync", "status"):
        sub = subparsers.add_parser(name)
        sub.add_argument("--config-file", required=True)

    args = parser.parse_args()
    commands = {"init": cmd_init, "sync": cmd_sync, "status": cmd_status}
    sys.exit(commands[args.command](args))
