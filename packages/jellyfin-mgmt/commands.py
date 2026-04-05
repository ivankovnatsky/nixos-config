"""CLI commands and argument parsing for jellyfin-mgmt."""

import sys
import json
import argparse

from client import JellyfinClient
from sync import sync_from_config


def cmd_list(args):
    """List all libraries."""
    client = JellyfinClient(args.base_url, args.api_key)
    try:
        libraries = client.list_libraries()
        if args.output_format == "json":
            print(json.dumps(libraries, indent=2))
        else:
            print("Libraries:")
            for library in libraries:
                lib_id = library.get("ItemId", "N/A")
                name = library.get("Name", "Unknown")
                lib_type = library.get("CollectionType", "Unknown")
                print(f"  {lib_id}: {name} ({lib_type})")
                if "Locations" in library and library["Locations"]:
                    print("  Paths:")
                    for path in library["Locations"]:
                        print(f"    - {path}")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_sync(args):
    """Sync libraries from configuration file."""
    try:
        with open(args.config_file, "r") as f:
            config = json.load(f)
    except Exception as e:
        print(f"Error loading config file: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        sync_from_config(config, dry_run=args.dry_run)

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
    parser = argparse.ArgumentParser(description="Jellyfin library management tool")

    subparsers = parser.add_subparsers(
        dest="command", required=True, help="Command to execute"
    )

    # List command
    list_parser = subparsers.add_parser("list", help="List all libraries")
    list_parser.add_argument("--base-url", required=True, help="Jellyfin URL")
    list_parser.add_argument("--api-key", required=True, help="API key")
    list_parser.add_argument(
        "--output-format",
        choices=["table", "json"],
        default="table",
        help="Output format",
    )

    # Sync command (declarative configuration)
    sync_parser = subparsers.add_parser(
        "sync", help="Sync libraries from configuration file"
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

    if args.command == "list":
        cmd_list(args)
    elif args.command == "sync":
        cmd_sync(args)
