#!/usr/bin/env python3
"""
Uptime Kuma monitor management tool.
Supports listing, creating, updating, and deleting monitors via declarative configuration.
"""

import sys
import json
import argparse
from uptime_kuma_api import UptimeKumaApi, MonitorType

USER_AGENT = "uptime-kuma-mgmt/1.0.0"


class UptimeKumaClient:
    def __init__(self, base_url: str, username: str, password: str):
        self.base_url = base_url.rstrip("/")
        self.api = UptimeKumaApi(self.base_url)
        self._authenticate(username, password)

    def _authenticate(self, username: str, password: str):
        """Authenticate with username and password."""
        try:
            self.api.login(username, password)
            print(f"Authenticated successfully", file=sys.stderr)
        except Exception as e:
            raise Exception(f"Authentication failed: {e}")

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        try:
            self.api.disconnect()
        except:
            pass

    def list_monitors(self):
        """List all monitors."""
        try:
            monitors = self.api.get_monitors()
            return monitors
        except Exception as e:
            raise Exception(f"Failed to list monitors: {e}")

    def get_monitor(self, monitor_id: int):
        """Get single monitor details."""
        try:
            monitor = self.api.get_monitor(monitor_id)
            return monitor
        except Exception as e:
            raise Exception(f"Failed to get monitor: {e}")

    def create_monitor(self, monitor_config: dict):
        """Create a new monitor."""
        try:
            result = self.api.add_monitor(**monitor_config)
            return result
        except Exception as e:
            raise Exception(f"Failed to create monitor: {e}")

    def update_monitor(self, monitor_id: int, monitor_config: dict):
        """Update an existing monitor."""
        try:
            monitor_config["id"] = monitor_id
            result = self.api.edit_monitor(monitor_id, **monitor_config)
            return result
        except Exception as e:
            raise Exception(f"Failed to update monitor: {e}")

    def delete_monitor(self, monitor_id: int):
        """Delete a monitor."""
        try:
            self.api.delete_monitor(monitor_id)
        except Exception as e:
            raise Exception(f"Failed to delete monitor: {e}")

    def sync_from_file(self, config_file: str, dry_run: bool = False):
        """
        Sync monitors from a JSON configuration file.
        Creates missing monitors, updates existing ones, deletes extras.
        """
        try:
            with open(config_file, "r") as f:
                config = json.load(f)
        except Exception as e:
            raise Exception(f"Failed to load config file: {e}")

        if "monitors" not in config:
            raise ValueError('Config file must contain "monitors" array')

        desired_monitors = {m["name"]: m for m in config["monitors"]}
        current_monitors = {m["name"]: m for m in self.list_monitors()}

        print(f"\nSync Plan:", file=sys.stderr)
        print(f"  Desired monitors: {len(desired_monitors)}", file=sys.stderr)
        print(f"  Current monitors: {len(current_monitors)}", file=sys.stderr)

        if dry_run:
            print("\nDry-run mode - no changes will be made\n", file=sys.stderr)

        # Create or update monitors
        for name, desired in desired_monitors.items():
            if name in current_monitors:
                current = current_monitors[name]
                needs_update = self._monitor_needs_update(desired, current)

                if needs_update:
                    print(f"  UPDATE: {name}", file=sys.stderr)
                    if not dry_run:
                        monitor_config = self._prepare_monitor_config(desired)
                        self.update_monitor(current["id"], monitor_config)
                else:
                    print(f"  OK: {name} (no changes)", file=sys.stderr)
            else:
                print(f"  CREATE: {name}", file=sys.stderr)
                if not dry_run:
                    monitor_config = self._prepare_monitor_config(desired)
                    self.create_monitor(monitor_config)

        # Delete monitors not in desired state (declarative)
        extra_monitors = set(current_monitors.keys()) - set(desired_monitors.keys())
        if extra_monitors:
            for name in extra_monitors:
                monitor_id = current_monitors[name]["id"]
                print(f"  DELETE: {name}", file=sys.stderr)
                if not dry_run:
                    self.delete_monitor(monitor_id)

        if dry_run:
            print("\nDry-run complete - no changes made.", file=sys.stderr)
        else:
            print("\nSync complete!", file=sys.stderr)

    def _monitor_needs_update(self, desired: dict, current: dict) -> bool:
        """Check if monitor configuration differs from current state."""
        # Compare key fields
        fields_to_compare = ["url", "interval", "maxretries", "retryInterval", "type"]
        for field in fields_to_compare:
            if desired.get(field) != current.get(field):
                return True

        # Compare expectedStatus (mapped to accepted_statuscodes in API)
        if "expectedStatus" in desired:
            desired_status = [str(desired["expectedStatus"])]
            current_status = current.get("accepted_statuscodes", ["200"])
            if desired_status != current_status:
                return True
        elif current.get("accepted_statuscodes") and current["accepted_statuscodes"] != ["200"]:
            # Current has non-default status but desired doesn't specify one
            return True

        return False

    def _prepare_monitor_config(self, monitor: dict) -> dict:
        """Prepare monitor configuration for API call."""
        config = {
            "type": self._get_monitor_type(monitor.get("type", "http")),
            "name": monitor["name"],
            "url": monitor["url"],
            "interval": monitor.get("interval", 60),
            "maxretries": monitor.get("maxretries", 3),
            "retryInterval": monitor.get("retryInterval", 60),
        }

        # Add optional fields
        if "description" in monitor:
            config["description"] = monitor["description"]
        if "expectedStatus" in monitor:
            config["accepted_statuscodes"] = [str(monitor["expectedStatus"])]
        if "timeout" in monitor:
            config["timeout"] = monitor["timeout"]

        return config

    def _get_monitor_type(self, type_str: str) -> MonitorType:
        """Convert string type to MonitorType enum."""
        type_map = {
            "http": MonitorType.HTTP,
            "https": MonitorType.HTTP,
            "tcp": MonitorType.PORT,
            "ping": MonitorType.PING,
            "dns": MonitorType.DNS,
        }
        return type_map.get(type_str.lower(), MonitorType.HTTP)


def cmd_list(args, client):
    """List all monitors."""
    try:
        monitors = client.list_monitors()
        if args.output_format == "json":
            print(json.dumps(monitors, indent=2))
        else:
            print("Monitors:")
            for monitor in monitors:
                status = "✓" if monitor.get("active") else "✗"
                print(
                    f"  [{status}] {monitor['id']}: {monitor['name']} - {monitor.get('url', 'N/A')}"
                )
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_get(args, client):
    """Get monitor details."""
    try:
        monitor = client.get_monitor(args.monitor_id)
        print(json.dumps(monitor, indent=2))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_sync(args, client):
    """Sync monitors from configuration file."""
    try:
        client.sync_from_file(args.config_file, dry_run=args.dry_run)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Uptime Kuma monitor management tool"
    )

    subparsers = parser.add_subparsers(
        dest="command", required=True, help="Command to execute"
    )

    # List command
    list_parser = subparsers.add_parser("list", help="List all monitors")
    list_parser.add_argument("--base-url", required=True, help="Uptime Kuma base URL")
    list_parser.add_argument("--username", required=True, help="Username")
    list_parser.add_argument("--password", required=True, help="Password")
    list_parser.add_argument(
        "--output-format",
        choices=["table", "json"],
        default="table",
        help="Output format",
    )

    # Get command
    get_parser = subparsers.add_parser("get", help="Get monitor details")
    get_parser.add_argument("--base-url", required=True, help="Uptime Kuma base URL")
    get_parser.add_argument("--username", required=True, help="Username")
    get_parser.add_argument("--password", required=True, help="Password")
    get_parser.add_argument("--monitor-id", required=True, type=int, help="Monitor ID")

    # Sync command (declarative configuration)
    sync_parser = subparsers.add_parser(
        "sync", help="Sync monitors from configuration file"
    )
    sync_parser.add_argument("--base-url", required=True, help="Uptime Kuma base URL")
    sync_parser.add_argument("--username", required=True, help="Username")
    sync_parser.add_argument("--password", required=True, help="Password")
    sync_parser.add_argument(
        "--config-file", required=True, help="JSON configuration file"
    )
    sync_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without making changes",
    )

    args = parser.parse_args()

    with UptimeKumaClient(args.base_url, args.username, args.password) as client:
        if args.command == "list":
            cmd_list(args, client)
        elif args.command == "get":
            cmd_get(args, client)
        elif args.command == "sync":
            cmd_sync(args, client)


if __name__ == "__main__":
    main()
