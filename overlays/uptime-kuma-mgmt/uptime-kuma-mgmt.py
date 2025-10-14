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
                needs_update, reason = self._monitor_needs_update(desired, current)

                if needs_update:
                    print(f"  UPDATE: {name} ({reason})", file=sys.stderr)
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

    def _mask_password_in_url(self, url: str) -> str:
        """Mask password in connection URLs for display purposes."""
        if not url or "://" not in url:
            return url

        try:
            # Handle postgres://user:password@host:port/db format
            if "://" in url and "@" in url:
                protocol, rest = url.split("://", 1)
                if "@" in rest:
                    credentials, host_part = rest.rsplit("@", 1)
                    if ":" in credentials:
                        user, _ = credentials.split(":", 1)
                        return f"{protocol}://{user}:***@{host_part}"
                    return url
            return url
        except Exception:
            return url

    def _monitor_needs_update(self, desired: dict, current: dict) -> tuple[bool, str]:
        """Check if monitor configuration differs from current state. Returns (needs_update, reason)."""
        # Compare basic fields (use defaults from _prepare_monitor_config)
        if desired.get("interval", 60) != current.get("interval"):
            return True, f"interval: {current.get('interval')} → {desired.get('interval', 60)}"
        if desired.get("maxretries", 3) != current.get("maxretries"):
            return True, f"maxretries: {current.get('maxretries')} → {desired.get('maxretries', 3)}"
        if desired.get("retryInterval", 60) != current.get("retryInterval"):
            return True, f"retryInterval: {current.get('retryInterval')} → {desired.get('retryInterval', 60)}"

        # Compare monitor type (normalize both to MonitorType enum values)
        desired_type = self._get_monitor_type(desired.get("type", "http"))
        current_type = self._get_monitor_type(current.get("type", "http"))
        if desired_type != current_type:
            return True, f"type: {current.get('type')} → {desired.get('type')}"

        # Compare monitor-type-specific fields
        monitor_type = desired.get("type", "http")

        if monitor_type in ["tcp", "mqtt"]:
            # For TCP/MQTT: compare hostname:port
            if ":" in desired.get("url", ""):
                hostname, port = desired["url"].rsplit(":", 1)
                current_port = current.get("port")
                # Handle port type differences (string vs int)
                if isinstance(current_port, str):
                    current_port = int(current_port)
                if current.get("hostname") != hostname:
                    return True, f"hostname: {current.get('hostname')} → {hostname}"
                if current_port != int(port):
                    return True, f"port: {current_port} → {port}"
        elif monitor_type == "dns":
            # For DNS: compare hostname@dns_server
            if "@" in desired.get("url", ""):
                hostname, dns_server = desired["url"].split("@", 1)
                if current.get("hostname") != hostname:
                    return True, f"hostname: {current.get('hostname')} → {hostname}"
                if current.get("dns_resolve_server") != dns_server:
                    return True, f"dns_server: {current.get('dns_resolve_server')} → {dns_server}"
        elif monitor_type == "postgres":
            # For Postgres: compare connection string
            if desired.get("url") != current.get("databaseConnectionString"):
                # Mask passwords in connection strings for display
                current_masked = self._mask_password_in_url(current.get('databaseConnectionString', ''))
                desired_masked = self._mask_password_in_url(desired.get('url', ''))
                return True, f"connection: {current_masked} → {desired_masked}"
        elif monitor_type == "tailscale-ping":
            # For Tailscale: compare hostname
            if desired.get("url") != current.get("hostname"):
                return True, f"hostname: {current.get('hostname')} → {desired.get('url')}"
        else:
            # For HTTP/HTTPS: compare URL
            if desired.get("url") != current.get("url"):
                return True, f"url: {current.get('url')} → {desired.get('url')}"

        # Compare expectedStatus (mapped to accepted_statuscodes in API)
        if "expectedStatus" in desired:
            desired_status = [str(desired["expectedStatus"])]
            current_status = current.get("accepted_statuscodes", ["200"])
            if desired_status != current_status:
                return True, f"status: {current_status} → {desired_status}"
        elif current.get("accepted_statuscodes") and current["accepted_statuscodes"] != ["200"]:
            # Current has non-default status but desired doesn't specify one
            return True, f"status: {current['accepted_statuscodes']} → ['200']"

        return False, ""

    def _prepare_monitor_config(self, monitor: dict) -> dict:
        """Prepare monitor configuration for API call."""
        monitor_type = self._get_monitor_type(monitor.get("type", "http"))

        config = {
            "type": monitor_type,
            "name": monitor["name"],
            "interval": monitor.get("interval", 60),
            "maxretries": monitor.get("maxretries", 3),
            "retryInterval": monitor.get("retryInterval", 60),
        }

        # Handle different monitor types
        if monitor_type == MonitorType.PORT:  # TCP port monitoring
            # For TCP monitors, split hostname:port
            if ":" in monitor["url"]:
                hostname, port = monitor["url"].rsplit(":", 1)
                config["hostname"] = hostname
                config["port"] = int(port)
            else:
                raise ValueError(f"TCP monitor requires hostname:port format, got: {monitor['url']}")
        elif monitor_type == MonitorType.DNS:
            # For DNS monitors, url format: "hostname@dns_server"
            if "@" in monitor["url"]:
                hostname, dns_server = monitor["url"].split("@", 1)
                config["hostname"] = hostname
                config["dns_resolve_server"] = dns_server
                config["dns_resolve_type"] = "A"
                config["port"] = 53
            else:
                raise ValueError(f"DNS monitor requires hostname@dns_server format, got: {monitor['url']}")
        elif monitor_type == MonitorType.POSTGRES:
            # For PostgreSQL monitors, url is the connection string
            config["databaseConnectionString"] = monitor["url"]
            config["databaseQuery"] = "SELECT 1"  # Simple health check query
        elif monitor_type == MonitorType.MQTT:
            # For MQTT monitors, split hostname:port
            if ":" in monitor["url"]:
                hostname, port = monitor["url"].rsplit(":", 1)
                config["hostname"] = hostname
                config["port"] = int(port)
                config["mqttTopic"] = "uptime-kuma/health"  # Default topic for health check
            else:
                raise ValueError(f"MQTT monitor requires hostname:port format, got: {monitor['url']}")
        elif monitor_type == MonitorType.TAILSCALE_PING:
            # For Tailscale Ping monitors, url is the hostname
            config["hostname"] = monitor["url"]
        else:
            # For HTTP/HTTPS monitors
            config["url"] = monitor["url"]

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
            "port": MonitorType.PORT,  # API returns "port" for TCP monitors
            "ping": MonitorType.PING,
            "dns": MonitorType.DNS,
            "postgres": MonitorType.POSTGRES,
            "mqtt": MonitorType.MQTT,
            "tailscale-ping": MonitorType.TAILSCALE_PING,
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
