"""CLI argument parsing and main entry point for uptime-kuma-mgmt."""

import sys
import argparse

from uptime_kuma_api import UptimeKumaException

from auth import add_auth_args, validate_auth_args
from client import UptimeKumaClient
from commands import cmd_list, cmd_get, cmd_sync


def main():
    parser = argparse.ArgumentParser(description="Uptime Kuma monitor management tool")

    subparsers = parser.add_subparsers(
        dest="command", required=True, help="Command to execute"
    )

    # List command
    list_parser = subparsers.add_parser("list", help="List all monitors")
    add_auth_args(list_parser)
    list_parser.add_argument(
        "--output-format",
        choices=["table", "json"],
        default="table",
        help="Output format",
    )

    # Get command
    get_parser = subparsers.add_parser("get", help="Get monitor details")
    add_auth_args(get_parser)
    get_parser.add_argument("--monitor-id", required=True, type=int, help="Monitor ID")

    # Sync command (declarative configuration)
    sync_parser = subparsers.add_parser(
        "sync", help="Sync monitors from configuration file"
    )
    add_auth_args(sync_parser)
    sync_parser.add_argument(
        "--config-file", required=True, help="JSON configuration file"
    )
    sync_parser.add_argument(
        "--discord-webhook", help="Discord webhook URL for notifications"
    )
    sync_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without making changes",
    )

    args = parser.parse_args()
    validate_auth_args(args)

    try:
        with UptimeKumaClient(args.base_url, args.username, args.password) as client:
            if args.command == "list":
                cmd_list(args, client)
            elif args.command == "get":
                cmd_get(args, client)
            elif args.command == "sync":
                cmd_sync(args, client)
    except UptimeKumaException:
        print(
            f"Error: Failed to connect to Uptime Kuma at {args.base_url}",
            file=sys.stderr,
        )
        print("  Please verify the server is running and accessible.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        error_msg = str(e)
        if (
            "Connection refused" in error_msg
            or "unable to connect" in error_msg.lower()
        ):
            print(
                f"Error: Failed to connect to Uptime Kuma at {args.base_url}",
                file=sys.stderr,
            )
            print(
                "  Please verify the server is running and accessible.",
                file=sys.stderr,
            )
        else:
            print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
