#!/usr/bin/env python3
"""
Syncthing configuration management tool.
Applies GUI credentials and device IDs via Syncthing REST API.
"""

import sys
import os
import argparse
import logging

from commands import cmd_list_devices, cmd_list_folders, cmd_status, cmd_scan
from sync import cmd_sync

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(message)s", stream=sys.stdout)


def main():
    parser = argparse.ArgumentParser(
        description="Syncthing configuration management tool",
        epilog="Default mode: CLI (use 'syncthing-mgmt' or 'syncthing-mgmt cli status')",
    )

    # Main subparsers for declarative vs cli mode
    mode_subparsers = parser.add_subparsers(dest="mode", help="Operation mode")

    # ===== CLI Mode (interactive, default) =====
    cli_parser = mode_subparsers.add_parser(
        "cli", help="CLI mode for interactive use (default)"
    )
    cli_subparsers = cli_parser.add_subparsers(
        dest="cli_command", help="CLI command to execute"
    )

    # Common arguments for CLI commands
    def add_cli_args(subparser):
        subparser.add_argument(
            "--base-url",
            help="Syncthing URL (default: http://127.0.0.1:8384, with fallback to local IPs)",
        )
        subparser.add_argument("--api-key", help="Syncthing API key")
        subparser.add_argument(
            "--config-xml", help="Path to Syncthing config.xml (to extract API key)"
        )

    # CLI: status command
    status_parser = cli_subparsers.add_parser(
        "status", help="Show status of configured devices and folders (default)"
    )
    add_cli_args(status_parser)

    # CLI: scan command
    scan_parser = cli_subparsers.add_parser(
        "scan", help="Trigger a rescan for one or more folders"
    )
    add_cli_args(scan_parser)
    scan_parser.add_argument(
        "folders", nargs="*", help="Folder IDs to scan (default: all folders)"
    )

    # CLI: list command with subcommands
    list_parser = cli_subparsers.add_parser("list", help="List configured resources")
    list_subparsers = list_parser.add_subparsers(
        dest="list_command", help="Resource type to list"
    )

    # CLI: list devices
    list_devices_parser = list_subparsers.add_parser(
        "devices", help="List all configured devices"
    )
    add_cli_args(list_devices_parser)

    # CLI: list folders
    list_folders_parser = list_subparsers.add_parser(
        "folders", help="List all configured folders"
    )
    add_cli_args(list_folders_parser)

    # ===== Declarative Mode (for NixOS/Darwin modules) =====
    declarative_parser = mode_subparsers.add_parser(
        "declarative", help="Declarative mode for NixOS/Darwin modules"
    )
    declarative_parser.add_argument("--base-url", required=True, help="Syncthing URL")
    declarative_parser.add_argument("--api-key", help="Syncthing API key")
    declarative_parser.add_argument(
        "--config-xml", help="Path to Syncthing config.xml (to extract API key)"
    )
    declarative_parser.add_argument(
        "--config-file", required=True, help="JSON configuration file"
    )
    declarative_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without making changes",
    )
    declarative_parser.add_argument(
        "--restart",
        action="store_true",
        help="Restart Syncthing after applying changes",
    )

    args = parser.parse_args()

    # Default to CLI mode with status command if no mode specified
    if not args.mode:
        args.mode = "cli"
        args.cli_command = "status"
        args.base_url = None
        args.api_key = None
        args.config_xml = None

    # Default to status for CLI mode if no command specified
    if args.mode == "cli" and not args.cli_command:
        args.cli_command = "status"

    # Try to auto-detect config.xml for CLI mode
    if args.mode == "cli":
        if not args.config_xml and not args.api_key:
            # Try common config locations (Linux and Darwin)
            possible_configs = [
                # Linux (user)
                os.path.expanduser("~/.local/state/syncthing/config.xml"),
                os.path.expanduser("~/.config/syncthing/config.xml"),
                # Linux (system)
                "/var/lib/syncthing/.config/syncthing/config.xml",
                # Darwin (macOS)
                os.path.expanduser(
                    "~/Library/Application Support/Syncthing/config.xml"
                ),
            ]
            for config_path in possible_configs:
                if os.path.exists(config_path):
                    args.config_xml = config_path
                    break

        # Default base URL to localhost if not provided
        if not args.base_url:
            args.base_url = "http://127.0.0.1:8384"

    # Route to appropriate command
    if args.mode == "declarative":
        cmd_sync(args)
    elif args.mode == "cli":
        if args.cli_command == "list":
            if hasattr(args, "list_command") and args.list_command == "devices":
                cmd_list_devices(args)
            elif hasattr(args, "list_command") and args.list_command == "folders":
                cmd_list_folders(args)
            else:
                list_parser.print_help()
        elif args.cli_command == "scan":
            cmd_scan(args)
        elif args.cli_command == "status":
            cmd_status(args)


if __name__ == "__main__":
    main()
