"""Beszel API client for authentication and system management."""

import json
import re

import click
import requests

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
            click.echo("Authenticated successfully", err=True)

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
                    click.echo(f"DEBUG: Error response: {error_data}", err=True)
                    message = error_data.get("message", "Unknown error")
                    raise Exception(
                        f"API error: {message} (Status: {response.status_code})"
                    )
                except ValueError:
                    click.echo(f"DEBUG: Response text: {response.text}", err=True)
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
                    click.echo("Discord webhook already configured", err=True)
                    return

                # Add Discord webhook
                webhooks.append(shoutrrr_url)
                click.echo("Adding Discord webhook to existing settings", err=True)

                # Update user settings
                updated_settings = {"emails": emails, "webhooks": webhooks}

                self._api_call(
                    "PATCH",
                    f"/api/collections/user_settings/records/{user_settings['id']}",
                    data={"settings": updated_settings},
                )
                click.echo("Discord webhook configured successfully", err=True)
            else:
                # Create new user settings
                click.echo("Creating new user settings with Discord webhook", err=True)
                settings = {"emails": [], "webhooks": [shoutrrr_url]}

                self._api_call(
                    "POST",
                    "/api/collections/user_settings/records",
                    data={"user": self.user_id, "settings": settings},
                )
                click.echo("Discord webhook configured successfully", err=True)

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

        click.echo("\nSync Plan:", err=True)
        click.echo(f"  Desired systems: {len(desired_systems)}", err=True)
        click.echo(f"  Current systems: {len(current_systems)}", err=True)

        if dry_run:
            click.echo("\nDry-run mode - no changes will be made\n", err=True)

        # Create or update systems
        for name, desired in desired_systems.items():
            if name in current_systems:
                current = current_systems[name]
                needs_update = desired.get("host") != current.get(
                    "host"
                ) or desired.get("port", "45876") != current.get("port")

                if needs_update:
                    click.echo(f"  UPDATE: {name}", err=True)
                    if not dry_run:
                        self.update_system(
                            current["id"],
                            host=desired.get("host"),
                            port=desired.get("port", "45876"),
                        )
                else:
                    click.echo(f"  OK: {name} (no changes)", err=True)
            else:
                click.echo(f"  CREATE: {name}", err=True)
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
                click.echo(f"  DELETE: {name}", err=True)
                if not dry_run:
                    self.delete_system(system_id)

        if dry_run:
            click.echo("\nDry-run complete - no changes made.", err=True)
        else:
            click.echo("\nSync complete!", err=True)
