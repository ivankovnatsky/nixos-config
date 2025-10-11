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
        self, name: str, paths: list, collection_type: str = "movies", refresh: bool = True
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
        return self._api_call("POST", "/Library/VirtualFolders/Paths", data=data, params=params)

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
            refresh = (i == len(paths_to_add) - 1)
            self.add_media_path(name, path, refresh=refresh)

    def delete_library(self, name: str):
        """Delete a library."""
        params = {"name": name}
        return self._api_call("DELETE", "/Library/VirtualFolders", params=params)



def sync_from_config(config, dry_run=False):
    """
    Sync libraries from configuration.
    Creates missing items, updates existing ones.
    """
    client = JellyfinClient(config["baseUrl"], config["apiKey"])

    # Sync libraries
    if "libraries" in config:
        _sync_libraries(client, config["libraries"], dry_run)


def _sync_libraries(client: JellyfinClient, libraries_config: list, dry_run: bool = False):
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
                client.create_library(name=name, paths=paths, collection_type=library_type)

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
    sync_parser.add_argument("--config-file", required=True, help="JSON configuration file")
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
