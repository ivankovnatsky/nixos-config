"""Argument parsing and CLI entry point for beszel-mgmt."""

import argparse

from client import BeszelClient
from commands import cmd_list, cmd_get, cmd_create, cmd_update, cmd_delete, cmd_sync


def main():
    parser = argparse.ArgumentParser(description="Beszel systems management tool")

    subparsers = parser.add_subparsers(
        dest="command", required=True, help="Command to execute"
    )

    # List command
    list_parser = subparsers.add_parser("list", help="List all systems")
    list_parser.add_argument("--base-url", required=True, help="Beszel base URL")
    list_parser.add_argument("--email", required=True, help="User email")
    list_parser.add_argument("--password", required=True, help="User password")
    list_parser.add_argument(
        "--output-format",
        choices=["table", "json"],
        default="table",
        help="Output format",
    )

    # Get command
    get_parser = subparsers.add_parser("get", help="Get system details")
    get_parser.add_argument("--base-url", required=True, help="Beszel base URL")
    get_parser.add_argument("--email", required=True, help="User email")
    get_parser.add_argument("--password", required=True, help="User password")
    get_parser.add_argument("--system-id", required=True, help="System ID")

    # Create command
    create_parser = subparsers.add_parser("create", help="Create a new system")
    create_parser.add_argument("--base-url", required=True, help="Beszel base URL")
    create_parser.add_argument("--email", required=True, help="User email")
    create_parser.add_argument("--password", required=True, help="User password")
    create_parser.add_argument("--name", required=True, help="System name")
    create_parser.add_argument("--host", required=True, help="System host/IP")
    create_parser.add_argument(
        "--port", default="45876", help="System port (default: 45876)"
    )

    # Update command
    update_parser = subparsers.add_parser("update", help="Update a system")
    update_parser.add_argument("--base-url", required=True, help="Beszel base URL")
    update_parser.add_argument("--email", required=True, help="User email")
    update_parser.add_argument("--password", required=True, help="User password")
    update_parser.add_argument("--system-id", required=True, help="System ID")
    update_parser.add_argument("--name", help="New system name")
    update_parser.add_argument("--host", help="New system host/IP")
    update_parser.add_argument("--port", help="New system port")

    # Delete command
    delete_parser = subparsers.add_parser("delete", help="Delete a system")
    delete_parser.add_argument("--base-url", required=True, help="Beszel base URL")
    delete_parser.add_argument("--email", required=True, help="User email")
    delete_parser.add_argument("--password", required=True, help="User password")
    delete_parser.add_argument("--system-id", required=True, help="System ID to delete")

    # Sync command (declarative configuration)
    sync_parser = subparsers.add_parser(
        "sync", help="Sync systems from configuration file"
    )
    sync_parser.add_argument("--base-url", required=True, help="Beszel base URL")
    sync_parser.add_argument("--email", required=True, help="User email")
    sync_parser.add_argument("--password", required=True, help="User password")
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

    client = BeszelClient(args.base_url, args.email, args.password)

    if args.command == "list":
        cmd_list(args, client)
    elif args.command == "get":
        cmd_get(args, client)
    elif args.command == "create":
        cmd_create(args, client)
    elif args.command == "update":
        cmd_update(args, client)
    elif args.command == "delete":
        cmd_delete(args, client)
    elif args.command == "sync":
        cmd_sync(args, client)
