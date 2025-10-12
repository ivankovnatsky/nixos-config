#!/usr/bin/env python3
"""
*arr stack management tool (Radarr, Sonarr, Prowlarr).
Declarative configuration via sync command.
"""

import sys
import json
import requests
import argparse

USER_AGENT = "arr-mgmt/1.0.0"


class ArrClient:
    def __init__(self, base_url: str, api_key: str, timeout: int = 120):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.headers = {
            "User-Agent": USER_AGENT,
            "X-Api-Key": api_key,
        }

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

            if response.status_code not in (200, 201, 202):
                try:
                    error_data = response.json()
                    print(f"DEBUG: Error response: {error_data}", file=sys.stderr)
                    # Handle both dict and list error responses
                    if isinstance(error_data, list) and len(error_data) > 0:
                        message = error_data[0].get("errorMessage", "Unknown error")
                    elif isinstance(error_data, dict):
                        message = error_data.get("error", "Unknown error")
                    else:
                        message = "Unknown error"
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

    def list_downloadclients(self):
        """List all download clients."""
        return self._api_call("GET", "/api/v3/downloadclient")

    def create_downloadclient(self, data):
        """Create a new download client."""
        return self._api_call("POST", "/api/v3/downloadclient", data=data)

    def update_downloadclient(self, client_id: int, data):
        """Update an existing download client."""
        return self._api_call("PUT", f"/api/v3/downloadclient/{client_id}", data=data)

    def delete_downloadclient(self, client_id: int):
        """Delete a download client."""
        return self._api_call("DELETE", f"/api/v3/downloadclient/{client_id}")

    def list_rootfolders(self):
        """List all root folders."""
        return self._api_call("GET", "/api/v3/rootfolder")

    def create_rootfolder(self, path: str):
        """Create a new root folder."""
        data = {"path": path}
        return self._api_call("POST", "/api/v3/rootfolder", data=data)

    def delete_rootfolder(self, folder_id: int):
        """Delete a root folder."""
        return self._api_call("DELETE", f"/api/v3/rootfolder/{folder_id}")


class ProwlarrClient:
    def __init__(self, base_url: str, api_key: str, timeout: int = 120):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.headers = {
            "User-Agent": USER_AGENT,
            "X-Api-Key": api_key,
        }

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

            if response.status_code not in (200, 201, 202):
                try:
                    error_data = response.json()
                    print(f"DEBUG: Error response: {error_data}", file=sys.stderr)
                    # Handle both dict and list error responses
                    if isinstance(error_data, list) and len(error_data) > 0:
                        message = error_data[0].get("errorMessage", "Unknown error")
                    elif isinstance(error_data, dict):
                        message = error_data.get("error", "Unknown error")
                    else:
                        message = "Unknown error"
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

    def list_applications(self):
        """List all applications."""
        return self._api_call("GET", "/api/v1/applications")

    def create_application(self, data):
        """Create a new application."""
        return self._api_call("POST", "/api/v1/applications", data=data)

    def update_application(self, app_id: int, data):
        """Update an existing application."""
        return self._api_call("PUT", f"/api/v1/applications/{app_id}", data=data)

    def delete_application(self, app_id: int):
        """Delete an application."""
        return self._api_call("DELETE", f"/api/v1/applications/{app_id}")

    def list_indexers(self):
        """List all indexers."""
        return self._api_call("GET", "/api/v1/indexer")

    def create_indexer(self, data):
        """Create a new indexer."""
        return self._api_call("POST", "/api/v1/indexer", data=data)

    def update_indexer(self, indexer_id: int, data):
        """Update an existing indexer."""
        return self._api_call("PUT", f"/api/v1/indexer/{indexer_id}", data=data)

    def delete_indexer(self, indexer_id: int):
        """Delete an indexer."""
        return self._api_call("DELETE", f"/api/v1/indexer/{indexer_id}")


def _build_transmission_fields(config, category_field="movieCategory"):
    """Build the fields array for Transmission download client."""
    fields = [
        {"name": "host", "value": config.get("host", "localhost")},
        {"name": "port", "value": config.get("port", 9091)},
        {"name": "useSsl", "value": config.get("useSsl", False)},
        {"name": "urlBase", "value": config.get("urlBase", "/transmission/")},
        {"name": "username", "value": config["username"]},
        {"name": "password", "value": config["password"]},
        {"name": category_field, "value": config.get("category", "")},
        {"name": "addPaused", "value": config.get("addPaused", False)},
    ]
    return fields


def sync_radarr(config, dry_run=False):
    """Sync Radarr configuration."""
    client = ArrClient(config["baseUrl"], config["apiKey"])

    print("", file=sys.stderr)
    print("=== Radarr Sync ===", file=sys.stderr)

    # Sync download clients
    if "downloadClients" in config:
        print("", file=sys.stderr)
        print("Syncing download clients...", file=sys.stderr)
        _sync_downloadclients(client, config["downloadClients"], "radarr", dry_run)

    # Sync root folders
    if "rootFolders" in config:
        print("", file=sys.stderr)
        print("Syncing root folders...", file=sys.stderr)
        _sync_rootfolders(client, config["rootFolders"], dry_run)

    print("", file=sys.stderr)
    print("Radarr sync complete!", file=sys.stderr)


def sync_sonarr(config, dry_run=False):
    """Sync Sonarr configuration."""
    client = ArrClient(config["baseUrl"], config["apiKey"])

    print("", file=sys.stderr)
    print("=== Sonarr Sync ===", file=sys.stderr)

    # Sync download clients
    if "downloadClients" in config:
        print("", file=sys.stderr)
        print("Syncing download clients...", file=sys.stderr)
        _sync_downloadclients(client, config["downloadClients"], "sonarr", dry_run)

    # Sync root folders
    if "rootFolders" in config:
        print("", file=sys.stderr)
        print("Syncing root folders...", file=sys.stderr)
        _sync_rootfolders(client, config["rootFolders"], dry_run)

    print("", file=sys.stderr)
    print("Sonarr sync complete!", file=sys.stderr)


def sync_prowlarr(config, dry_run=False):
    """Sync Prowlarr configuration."""
    client = ProwlarrClient(config["baseUrl"], config["apiKey"])

    print("", file=sys.stderr)
    print("=== Prowlarr Sync ===", file=sys.stderr)

    # Sync indexers
    if "indexers" in config:
        print("", file=sys.stderr)
        print("Syncing indexers...", file=sys.stderr)
        _sync_indexers(client, config["indexers"], dry_run)

    # Sync applications
    if "applications" in config:
        print("", file=sys.stderr)
        print("Syncing applications...", file=sys.stderr)
        _sync_applications(client, config["applications"], dry_run)

    print("", file=sys.stderr)
    print("Prowlarr sync complete!", file=sys.stderr)


def _sync_downloadclients(client: ArrClient, desired_clients: list, service_type: str, dry_run: bool):
    """Sync download clients for Radarr or Sonarr."""
    current_clients = {dc["name"]: dc for dc in client.list_downloadclients()}
    desired_clients_map = {dc["name"]: dc for dc in desired_clients}

    category_field = "movieCategory" if service_type == "radarr" else "tvCategory"

    for name, desired in desired_clients_map.items():
        if name in current_clients:
            current = current_clients[name]

            # Check if update needed
            needs_update = False
            update_parts = []

            # Build new fields
            new_fields = _build_transmission_fields(desired, category_field)

            # Compare fields (skip password comparison if masked)
            current_fields = {f["name"]: f for f in current.get("fields", [])}
            for field in new_fields:
                field_name = field["name"]
                if field_name == "password":
                    if desired["password"] != "********":
                        needs_update = True
                        update_parts.append("password")
                elif field_name in current_fields:
                    if field["value"] != current_fields[field_name].get("value"):
                        needs_update = True
                        update_parts.append(field_name)

            if needs_update:
                print(f"  UPDATE: {name} ({', '.join(update_parts)})", file=sys.stderr)
                if not dry_run:
                    # Build full update payload
                    update_data = current.copy()
                    update_data["fields"] = new_fields
                    client.update_downloadclient(current["id"], update_data)
            else:
                print(f"  OK: {name} (no changes)", file=sys.stderr)
        else:
            print(f"  CREATE: {name}", file=sys.stderr)
            if not dry_run:
                # Build create payload
                create_data = {
                    "enable": desired.get("enable", True),
                    "protocol": "torrent",
                    "priority": desired.get("priority", 1),
                    "removeCompletedDownloads": desired.get("removeCompletedDownloads", True),
                    "removeFailedDownloads": desired.get("removeFailedDownloads", True),
                    "name": name,
                    "fields": _build_transmission_fields(desired, category_field),
                    "implementationName": "Transmission",
                    "implementation": "Transmission",
                    "configContract": "TransmissionSettings",
                    "tags": [],
                }
                client.create_downloadclient(create_data)


def _sync_rootfolders(client: ArrClient, desired_folders: list, dry_run: bool):
    """Sync root folders."""
    current_folders = {rf["path"]: rf for rf in client.list_rootfolders()}

    for desired_path in desired_folders:
        if desired_path in current_folders:
            print(f"  OK: {desired_path} (already exists)", file=sys.stderr)
        else:
            print(f"  CREATE: {desired_path}", file=sys.stderr)
            if not dry_run:
                client.create_rootfolder(desired_path)


def _sync_applications(client: ProwlarrClient, desired_apps: list, dry_run: bool):
    """Sync Prowlarr applications."""
    current_apps = {app["name"]: app for app in client.list_applications()}
    desired_apps_map = {app["name"]: app for app in desired_apps}

    for name, desired in desired_apps_map.items():
        if name in current_apps:
            current = current_apps[name]

            # Check if update needed
            needs_update = False
            update_parts = []

            # Build fields
            new_fields = [
                {"name": "prowlarrUrl", "value": desired.get("prowlarrUrl", "http://localhost:9696")},
                {"name": "baseUrl", "value": desired["baseUrl"]},
                {"name": "apiKey", "value": desired["apiKey"]},
                {"name": "syncCategories", "value": desired.get("syncCategories", [])},
            ]

            # Compare fields (skip apiKey if masked)
            current_fields = {f["name"]: f for f in current.get("fields", [])}
            for field in new_fields:
                field_name = field["name"]
                if field_name == "apiKey":
                    if desired["apiKey"] != "********":
                        needs_update = True
                        update_parts.append("apiKey")
                elif field_name in current_fields:
                    if field["value"] != current_fields[field_name].get("value"):
                        needs_update = True
                        update_parts.append(field_name)

            # Check syncLevel
            if desired.get("syncLevel") != current.get("syncLevel"):
                needs_update = True
                update_parts.append("syncLevel")

            if needs_update:
                print(f"  UPDATE: {name} ({', '.join(update_parts)})", file=sys.stderr)
                if not dry_run:
                    update_data = current.copy()
                    update_data["syncLevel"] = desired.get("syncLevel", "fullSync")
                    update_data["fields"] = new_fields
                    client.update_application(current["id"], update_data)
            else:
                print(f"  OK: {name} (no changes)", file=sys.stderr)
        else:
            print(f"  CREATE: {name}", file=sys.stderr)
            if not dry_run:
                # Determine implementation based on name
                implementation = "Radarr" if "radarr" in name.lower() else "Sonarr"
                create_data = {
                    "syncLevel": desired.get("syncLevel", "fullSync"),
                    "enable": desired.get("enable", True),
                    "name": name,
                    "fields": [
                        {"name": "prowlarrUrl", "value": desired.get("prowlarrUrl", "http://localhost:9696")},
                        {"name": "baseUrl", "value": desired["baseUrl"]},
                        {"name": "apiKey", "value": desired["apiKey"]},
                        {"name": "syncCategories", "value": desired.get("syncCategories", [])},
                    ],
                    "implementationName": implementation,
                    "implementation": implementation,
                    "configContract": f"{implementation}Settings",
                    "tags": [],
                }
                client.create_application(create_data)


def _sync_indexers(client: ProwlarrClient, desired_indexers: list, dry_run: bool):
    """Sync Prowlarr indexers."""
    current_indexers = {idx["name"]: idx for idx in client.list_indexers()}
    desired_indexers_map = {idx["name"]: idx for idx in desired_indexers}

    # Delete indexers not in desired config
    for name, current in current_indexers.items():
        if name not in desired_indexers_map:
            print(f"  DELETE: {name} (not in config)", file=sys.stderr)
            if not dry_run:
                client.delete_indexer(current["id"])

    # Create or update indexers from desired config
    for name, desired in desired_indexers_map.items():
        if name in current_indexers:
            current = current_indexers[name]

            # Check if update needed
            needs_update = False
            update_parts = []

            # Check enable status
            if desired.get("enable", True) != current.get("enable"):
                needs_update = True
                update_parts.append(f"enable: {current.get('enable')} -> {desired.get('enable', True)}")

            # Check priority
            if desired.get("priority", 25) != current.get("priority"):
                needs_update = True
                update_parts.append(f"priority: {current.get('priority')} -> {desired.get('priority', 25)}")

            if needs_update:
                print(f"  UPDATE: {name} ({', '.join(update_parts)})", file=sys.stderr)
                if not dry_run:
                    update_data = current.copy()
                    update_data["enable"] = desired.get("enable", True)
                    update_data["priority"] = desired.get("priority", 25)
                    client.update_indexer(current["id"], update_data)
            else:
                print(f"  OK: {name} (no changes)", file=sys.stderr)
        else:
            # Create new indexer
            if "definitionName" not in desired:
                print(f"  ERROR: {name} (missing definitionName - required for creation)", file=sys.stderr)
                continue

            print(f"  CREATE: {name} (definitionName: {desired['definitionName']})", file=sys.stderr)
            if not dry_run:
                # Build create payload with implementation fields
                # Most public indexers use Cardigann (generic indexer framework)
                create_data = {
                    "definitionName": desired["definitionName"],
                    "name": name,
                    "enable": desired.get("enable", True),
                    "priority": desired.get("priority", 25),
                    "appProfileId": 1,  # Default app profile
                    "protocol": "torrent",
                    "implementationName": "Cardigann",
                    "implementation": "Cardigann",
                    "configContract": "CardigannSettings",
                    "fields": [
                        {"name": "definitionFile", "value": desired["definitionName"]}
                    ]
                }
                client.create_indexer(create_data)


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
