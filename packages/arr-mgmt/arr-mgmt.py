#!/usr/bin/env python3
"""
*arr stack management tool (Radarr, Sonarr, Prowlarr).
Declarative configuration via sync command.
"""

import sys
import json
import argparse

from sync import sync_radarr, sync_sonarr, sync_prowlarr


def cmd_sync(args):
    """Sync *arr configuration from JSON file."""
    try:
        with open(args.config_file, "r") as f:
            config = json.load(f)
    except Exception as e:
        print(f"Error loading config file: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        if "radarr" in config:
            sync_radarr(config["radarr"], dry_run=args.dry_run)

        if "sonarr" in config:
            sync_sonarr(config["sonarr"], dry_run=args.dry_run)

        if "prowlarr" in config:
            sync_prowlarr(config["prowlarr"], dry_run=args.dry_run)

        if args.dry_run:
            print("", file=sys.stderr)
            print("Dry-run complete - no changes made.", file=sys.stderr)
        else:
            print("", file=sys.stderr)
            print("Sync complete!", file=sys.stderr)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="*arr stack management tool (Radarr, Sonarr, Prowlarr)"
    )

    subparsers = parser.add_subparsers(
        dest="command", required=True, help="Command to execute"
    )

    # Sync command (declarative configuration)
    sync_parser = subparsers.add_parser(
        "sync", help="Sync *arr configuration from JSON file"
    )
    sync_parser.add_argument(
        "--config-file", required=True, help="JSON configuration file"
    )
    sync_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without making changes",
    )

    args = parser.parse_args()

    if args.command == "sync":
        cmd_sync(args)


if __name__ == "__main__":
    main()
