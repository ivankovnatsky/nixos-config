#!/usr/bin/env python3
"""
Jellyfin management tool.
Declarative library and user configuration via sync command.
"""

import sys
import json
import requests
import argparse

USER_AGENT = "jellyfin-mgmt/1.0.0"


class JellyfinClient:
    def __init__(self, base_url: str, api_key: str, timeout: int = 120):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.headers = {
            "User-Agent": USER_AGENT,
            "X-Emby-Token": api_key,
        }

    def _api_call(self, method: str, endpoint: str, data=None, params=None):
        """Make API request with error handling."""
        url = f"{self.base_url}{endpoint}"
        try:
            # Only include json parameter if data is not None
            # This prevents Content-Type: application/json header when we only want query params
            request_kwargs = {
                "method": method,
                "url": url,
                "params": params,
                "headers": self.headers,
                "timeout": self.timeout,
            }
            if data is not None:
                request_kwargs["json"] = data

            response = requests.request(**request_kwargs)

            if response.status_code == 429:
                raise Exception("API rate limit exceeded. Please wait before retrying.")

            if response.status_code == 204:
                return None

            if response.status_code not in (200, 201):
                try:
                    error_data = response.json()
                    print(f"DEBUG: Error response: {error_data}", file=sys.stderr)
                    message = error_data.get("error", "Unknown error")
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

    def list_libraries(self):
        """List all virtual folders (libraries)."""
        data = self._api_call("GET", "/Library/VirtualFolders")
        return data if data else []

    def create_library(
        self,
        name: str,
        paths: list,
        collection_type: str = "movies",
        refresh: bool = True,
    ):
        """Create a new virtual folder (library)."""
        params = {
            "name": name,
            "collectionType": collection_type,
            "paths": paths,
            "refreshLibrary": refresh,
        }
        return self._api_call("POST", "/Library/VirtualFolders", params=params)

    def remove_media_path(self, name: str, path: str):
        """Remove a single media path from a library."""
        params = {"name": name, "path": path}
        return self._api_call("DELETE", "/Library/VirtualFolders/Paths", params=params)

    def add_media_path(self, name: str, path: str, refresh: bool = True):
        """Add a single media path to a library."""
        data = {
            "Name": name,
            "Path": path,
        }
        params = {"refreshLibrary": refresh}
        return self._api_call(
            "POST", "/Library/VirtualFolders/Paths", data=data, params=params
        )

    def update_library_paths(self, name: str, current_paths: list, desired_paths: list):
        """Update library paths by removing old and adding new paths.

        Args:
            name: Library name
            current_paths: List of current paths in the library
            desired_paths: List of desired paths
        """
        # Remove paths that are no longer needed
        paths_to_remove = set(current_paths) - set(desired_paths)
        for path in paths_to_remove:
            self.remove_media_path(name, path)

        # Add new paths
        paths_to_add = set(desired_paths) - set(current_paths)
        for i, path in enumerate(paths_to_add):
            # Only refresh on the last path
            refresh = i == len(paths_to_add) - 1
            self.add_media_path(name, path, refresh=refresh)

    def delete_library(self, name: str):
        """Delete a library."""
        params = {"name": name}
        return self._api_call("DELETE", "/Library/VirtualFolders", params=params)

    def get_network_config(self):
        """Get current network configuration."""
        # Jellyfin stores network configuration separately
        config = self._api_call("GET", "/System/Configuration/network")
        # Extract only network-related fields
        return {
            "LocalNetworkAddresses": config.get("LocalNetworkAddresses", []),
            "InternalHttpPort": config.get("InternalHttpPort", 8096),
            "PublicHttpPort": config.get("PublicHttpPort", 8096),
        }

    def update_network_config(self, local_network_addresses: list):
        """Update network configuration (bind addresses)."""
        # Get current network configuration (stored separately from main config)
        current_network_config = self._api_call("GET", "/System/Configuration/network")

        # Update only the LocalNetworkAddresses field
        current_network_config["LocalNetworkAddresses"] = local_network_addresses

        # POST the network configuration back to the network endpoint
        return self._api_call(
            "POST", "/System/Configuration/network", data=current_network_config
        )

    def get_library_id(self, name: str):
        """Get library ID by name."""
        libraries = self.list_libraries()
        for lib in libraries:
            if lib.get("Name") == name:
                return lib.get("ItemId")
        return None

    def get_library_options(self, library_id: str):
        """Get current library options for a library."""
        libraries = self.list_libraries()
        for lib in libraries:
            if lib.get("ItemId") == library_id:
                return lib.get("LibraryOptions", {})
        return {}

    def update_library_options(self, library_id: str, library_options: dict):
        """Update library options for a specific library."""
        data = {"Id": library_id, "LibraryOptions": library_options}
        return self._api_call(
            "POST", "/Library/VirtualFolders/LibraryOptions", data=data
        )


def sync_from_config(config, dry_run=False):
    """
    Sync libraries and network configuration.
    Creates missing items, updates existing ones.
    """
    client = JellyfinClient(config["baseUrl"], config["apiKey"])

    # Sync network configuration (bind address)
    if "networkConfig" in config:
        _sync_network_config(client, config["networkConfig"], dry_run)

    # Sync libraries
    if "libraries" in config:
        _sync_libraries(client, config["libraries"], dry_run)


def _sync_network_config(client: JellyfinClient, network_config: dict, dry_run: bool):
    """Sync network configuration (bind addresses)."""
    current = client.get_network_config()
    desired_addresses = network_config.get("localNetworkAddresses", [])
    current_addresses = current.get("LocalNetworkAddresses", [])

    print("", file=sys.stderr)
    print("=== Network Configuration Sync ===", file=sys.stderr)

    if set(current_addresses) != set(desired_addresses):
        print("  UPDATE: LocalNetworkAddresses", file=sys.stderr)
        print(f"    Current: {current_addresses}", file=sys.stderr)
        print(f"    Desired: {desired_addresses}", file=sys.stderr)
        if not dry_run:
            try:
                result = client.update_network_config(desired_addresses)
                print(f"  DEBUG: API call result: {result}", file=sys.stderr)
                print(
                    "  NOTE: Jellyfin service must be restarted for changes to take effect",
                    file=sys.stderr,
                )
            except Exception as e:
                print(f"  ERROR: Failed to update network config: {e}", file=sys.stderr)
                raise
    else:
        print("  OK: LocalNetworkAddresses (no changes)", file=sys.stderr)


def _sync_libraries(
    client: JellyfinClient, libraries_config: list, dry_run: bool = False
):
    """Sync libraries from configuration."""
    desired_libraries = {lib["name"]: lib for lib in libraries_config}
    current_libraries = {lib["Name"]: lib for lib in client.list_libraries()}

    print("", file=sys.stderr)
    print("=== Library Sync ===", file=sys.stderr)
    print(f"  Desired libraries: {len(desired_libraries)}", file=sys.stderr)
    print(f"  Current libraries: {len(current_libraries)}", file=sys.stderr)

    if dry_run:
        print("", file=sys.stderr)
        print("Dry-run mode - no changes will be made", file=sys.stderr)
        print("", file=sys.stderr)

    # Create or update libraries
    for name, desired in desired_libraries.items():
        paths = desired["paths"]
        library_type = desired.get("type", "movies")

        if name in current_libraries:
            current = current_libraries[name]

            # Check if paths need update
            current_paths_list = current.get("Locations", [])
            current_paths = set(current_paths_list)
            desired_paths = set(paths)
            paths_changed = current_paths != desired_paths

            if paths_changed:
                print(
                    f"  UPDATE: {name} (paths: {current_paths} -> {desired_paths})",
                    file=sys.stderr,
                )
                if not dry_run:
                    client.update_library_paths(name, current_paths_list, paths)
            else:
                print(f"  OK: {name} (no changes)", file=sys.stderr)
        else:
            print(f"  CREATE: {name} (type: {library_type})", file=sys.stderr)
            if not dry_run:
                client.create_library(
                    name=name, paths=paths, collection_type=library_type
                )

    # Sync library options (after all libraries are created/updated)
    if "libraryOptions" in desired or any(
        "libraryOptions" in lib for lib in desired_libraries.values()
    ):
        print("", file=sys.stderr)
        print("=== Library Options Sync ===", file=sys.stderr)
        for name, desired in desired_libraries.items():
            desired_lib_options = desired.get("libraryOptions", {})
            if not desired_lib_options:
                continue

            library_id = client.get_library_id(name)
            if not library_id:
                print(
                    f"  WARNING: Could not find library ID for {name}", file=sys.stderr
                )
                continue

            current_lib_options = client.get_library_options(library_id)

            # Check if library options need update
            options_changed = False
            changes = []

            if "enableRealtimeMonitor" in desired_lib_options:
                desired_monitor = desired_lib_options["enableRealtimeMonitor"]
                current_monitor = current_lib_options.get(
                    "EnableRealtimeMonitor", False
                )
                if desired_monitor != current_monitor:
                    options_changed = True
                    changes.append(
                        f"EnableRealtimeMonitor: {current_monitor} -> {desired_monitor}"
                    )

            if "automaticRefreshIntervalDays" in desired_lib_options:
                desired_interval = desired_lib_options["automaticRefreshIntervalDays"]
                current_interval = current_lib_options.get(
                    "AutomaticRefreshIntervalDays", 0
                )
                if desired_interval != current_interval:
                    options_changed = True
                    changes.append(
                        f"AutomaticRefreshIntervalDays: {current_interval} -> {desired_interval}"
                    )

            if options_changed:
                print(f"  UPDATE: {name} library options", file=sys.stderr)
                for change in changes:
                    print(f"    {change}", file=sys.stderr)
                if not dry_run:
                    # Merge desired options into current options
                    updated_options = current_lib_options.copy()
                    if "enableRealtimeMonitor" in desired_lib_options:
                        updated_options["EnableRealtimeMonitor"] = desired_lib_options[
                            "enableRealtimeMonitor"
                        ]
                    if "automaticRefreshIntervalDays" in desired_lib_options:
                        updated_options["AutomaticRefreshIntervalDays"] = (
                            desired_lib_options["automaticRefreshIntervalDays"]
                        )

                    client.update_library_options(library_id, updated_options)
            else:
                print(f"  OK: {name} library options (no changes)", file=sys.stderr)

    if dry_run:
        print("", file=sys.stderr)
        print("Library sync dry-run complete - no changes made.", file=sys.stderr)
    else:
        print("", file=sys.stderr)
        print("Library sync complete!", file=sys.stderr)


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


if __name__ == "__main__":
    main()
