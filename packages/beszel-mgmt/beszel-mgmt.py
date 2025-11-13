#!/usr/bin/env python3
"""
Beszel systems management tool.
Supports listing, creating, updating, and deleting systems (machines).
"""

import sys
import json
import re
import requests
import argparse

USER_AGENT = "beszel-mgmt/1.0.0"


class BeszelClient:
    def __init__(self, base_url: str, email: str, password: str, timeout: int = 120):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.headers = {"User-Agent": USER_AGENT}
        self.token = None
        self.user_id = None
        self._authenticate(email, password)

    def _authenticate(self, email: str, password: str):
        """Authenticate with email and password."""
        url = f"{self.base_url}/api/collections/users/auth-with-password"
        try:
            response = requests.post(
                url,
                json={"identity": email, "password": password},
                headers=self.headers,
                timeout=self.timeout,
            )

            if response.status_code != 200:
                try:
                    error_data = response.json()
                    raise Exception(
                        f"Authentication failed: {error_data} (Status: {response.status_code})"
                    )
                except ValueError:
                    raise Exception(
                        f"Authentication failed with status {response.status_code}"
                    )

            data = response.json()
            self.token = data.get("token")
            if not self.token:
                raise Exception("No token received from authentication")

            self.user_id = data.get("record", {}).get("id")
            if not self.user_id:
                raise Exception("No user ID received from authentication")

            self.headers["Authorization"] = self.token
            print("Authenticated successfully", file=sys.stderr)

        except requests.exceptions.RequestException as e:
            raise Exception(f"Authentication network error: {e}")

    def _api_call(self, method: str, endpoint: str, data=None):
        """Make API request with error handling."""
        url = f"{self.base_url}{endpoint}"
        try:
            response = requests.request(
                method, url, json=data, headers=self.headers, timeout=self.timeout
            )

            if response.status_code == 429:
                raise Exception("API rate limit exceeded. Please wait before retrying.")

            if response.status_code == 204:
                return None

            if response.status_code not in (200, 201):
                try:
                    error_data = response.json()
                    print(f"DEBUG: Error response: {error_data}", file=sys.stderr)
                    message = error_data.get("message", "Unknown error")
                    raise Exception(
                        f"API error: {message} (Status: {response.status_code})"
                    )
                except ValueError:
                    print(f"DEBUG: Response text: {response.text}", file=sys.stderr)
                    raise Exception(
                        f"API request failed with status {response.status_code}"
                    )

            return response.json()
        except requests.exceptions.RequestException as e:
            raise Exception(f"Network error: {e}")

    @staticmethod
    def _discord_webhook_to_shoutrrr(webhook_url: str) -> str:
        """Convert Discord webhook URL to Shoutrrr format."""
        pattern = r"https://discord\.com/api/webhooks/(\d+)/([A-Za-z0-9_-]+)"
        match = re.match(pattern, webhook_url)
        if not match:
            raise ValueError(f"Invalid Discord webhook URL format: {webhook_url}")
        webhook_id, token = match.groups()
        return f"discord://{token}@{webhook_id}"

    def list_systems(self):
        """List all systems."""
        data = self._api_call("GET", "/api/collections/systems/records")
        return data.get("items", [])

    def get_system(self, system_id: str):
        """Get single system details."""
        return self._api_call("GET", f"/api/collections/systems/records/{system_id}")

    def create_system(self, name: str, host: str, port: str = "45876", users=None):
        """Create a new system."""
        data = {"name": name, "host": host, "port": port}

        if users:
            data["users"] = users
        elif self.user_id:
            data["users"] = [self.user_id]

        return self._api_call("POST", "/api/collections/systems/records", data=data)

    def update_system(
        self, system_id: str, name: str = None, host: str = None, port: str = None
    ):
        """Update an existing system."""
        data = {}
        if name is not None:
            data["name"] = name
        if host is not None:
            data["host"] = host
        if port is not None:
            data["port"] = port

        return self._api_call(
            "PATCH", f"/api/collections/systems/records/{system_id}", data=data
        )

    def delete_system(self, system_id: str):
        """Delete a system."""
        return self._api_call("DELETE", f"/api/collections/systems/records/{system_id}")

    def get_user_settings(self):
        """Get user notification settings."""
        data = self._api_call(
            "GET",
            f"/api/collections/user_settings/records?filter=user='{self.user_id}'",
        )
        items = data.get("items", [])
        if not items:
            return None
        return items[0]

    def setup_discord_notification(self, discord_webhook_url: str):
        """Setup Discord notification via Shoutrrr webhook."""
        try:
            # Convert Discord webhook URL to Shoutrrr format
            shoutrrr_url = self._discord_webhook_to_shoutrrr(discord_webhook_url)

            # Get current user settings
            user_settings = self.get_user_settings()

            if user_settings:
                # Parse existing settings
                settings = user_settings.get("settings", {})
                if isinstance(settings, str):
                    settings = json.loads(settings)

                webhooks = settings.get("webhooks", [])
                emails = settings.get("emails", [])

                # Check if webhook already exists
                if shoutrrr_url in webhooks:
                    print("Discord webhook already configured", file=sys.stderr)
                    return

                # Add Discord webhook
                webhooks.append(shoutrrr_url)
                print("Adding Discord webhook to existing settings", file=sys.stderr)

                # Update user settings
                updated_settings = {"emails": emails, "webhooks": webhooks}

                self._api_call(
                    "PATCH",
                    f"/api/collections/user_settings/records/{user_settings['id']}",
                    data={"settings": updated_settings},
                )
                print("Discord webhook configured successfully", file=sys.stderr)
            else:
                # Create new user settings
                print(
                    "Creating new user settings with Discord webhook", file=sys.stderr
                )
                settings = {"emails": [], "webhooks": [shoutrrr_url]}

                self._api_call(
                    "POST",
                    "/api/collections/user_settings/records",
                    data={"user": self.user_id, "settings": settings},
                )
                print("Discord webhook configured successfully", file=sys.stderr)

        except Exception as e:
            raise Exception(f"Failed to setup Discord notification: {e}")

    def sync_from_file(
        self, config_file: str, dry_run: bool = False, discord_webhook: str = None
    ):
        """
        Sync systems from a JSON configuration file.
        Creates missing systems, updates existing ones, deletes extras.
        """
        try:
            with open(config_file, "r") as f:
                config = json.load(f)
        except Exception as e:
            raise Exception(f"Failed to load config file: {e}")

        if "systems" not in config:
            raise ValueError('Config file must contain "systems" array')

        # Setup Discord notification if webhook URL is provided
        if discord_webhook and not dry_run:
            self.setup_discord_notification(discord_webhook)

        desired_systems = {s["name"]: s for s in config["systems"]}
        current_systems = {s["name"]: s for s in self.list_systems()}

        print("\nSync Plan:", file=sys.stderr)
        print(f"  Desired systems: {len(desired_systems)}", file=sys.stderr)
        print(f"  Current systems: {len(current_systems)}", file=sys.stderr)

        if dry_run:
            print("\nDry-run mode - no changes will be made\n", file=sys.stderr)

        # Create or update systems
        for name, desired in desired_systems.items():
            if name in current_systems:
                current = current_systems[name]
                needs_update = desired.get("host") != current.get(
                    "host"
                ) or desired.get("port", "45876") != current.get("port")

                if needs_update:
                    print(f"  UPDATE: {name}", file=sys.stderr)
                    if not dry_run:
                        self.update_system(
                            current["id"],
                            host=desired.get("host"),
                            port=desired.get("port", "45876"),
                        )
                else:
                    print(f"  OK: {name} (no changes)", file=sys.stderr)
            else:
                print(f"  CREATE: {name}", file=sys.stderr)
                if not dry_run:
                    self.create_system(
                        name=name,
                        host=desired["host"],
                        port=desired.get("port", "45876"),
                    )

        # Delete systems not in desired state (declarative)
        extra_systems = set(current_systems.keys()) - set(desired_systems.keys())
        if extra_systems:
            for name in extra_systems:
                system_id = current_systems[name]["id"]
                print(f"  DELETE: {name}", file=sys.stderr)
                if not dry_run:
                    self.delete_system(system_id)

        if dry_run:
            print("\nDry-run complete - no changes made.", file=sys.stderr)
        else:
            print("\nSync complete!", file=sys.stderr)


def cmd_list(args, client):
    """List all systems."""
    try:
        systems = client.list_systems()
        if args.output_format == "json":
            print(json.dumps(systems, indent=2))
        else:
            print("Systems:")
            for system in systems:
                print(
                    f"  {system['id']}: {system['name']} ({system['host']}:{system['port']})"
                )
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_get(args, client):
    """Get system details."""
    try:
        system = client.get_system(args.system_id)
        print(json.dumps(system, indent=2))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_create(args, client):
    """Create a new system."""
    try:
        system = client.create_system(args.name, args.host, args.port)
        print(f"Created system: {system['id']}")
        print(json.dumps(system, indent=2))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_update(args, client):
    """Update a system."""
    try:
        system = client.update_system(args.system_id, args.name, args.host, args.port)
        print(f"Updated system: {args.system_id}")
        print(json.dumps(system, indent=2))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_delete(args, client):
    """Delete a system."""
    try:
        client.delete_system(args.system_id)
        print(f"Deleted system: {args.system_id}")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_sync(args, client):
    """Sync systems from configuration file."""
    try:
        client.sync_from_file(
            args.config_file, dry_run=args.dry_run, discord_webhook=args.discord_webhook
        )
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


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


if __name__ == "__main__":
    main()
