#!/usr/bin/env python3
"""
Audiobookshelf library management tool.
Declarative library configuration via sync command.
"""

import sys
import json
import requests
import argparse

USER_AGENT = "abs-mgmt/1.0.0"


class AudiobookshelfClient:
    def __init__(self, base_url: str, api_token: str, timeout: int = 120):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.headers = {
            "User-Agent": USER_AGENT,
            "Authorization": f"Bearer {api_token}",
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
        """List all libraries."""
        data = self._api_call("GET", "/api/libraries")
        return data.get("libraries", [])

    def create_library(self, name: str, folders: list, media_type: str = "podcast"):
        """Create a new library."""
        data = {
            "name": name,
            "folders": folders,
            "mediaType": media_type,
        }
        return self._api_call("POST", "/api/libraries", data=data)

    def update_library(self, library_id: str, name: str = None, folders: list = None):
        """Update an existing library."""
        data = {}
        if name is not None:
            data["name"] = name
        if folders is not None:
            data["folders"] = folders

        return self._api_call("PATCH", f"/api/libraries/{library_id}", data=data)

    def delete_library(self, library_id: str):
        """Delete a library."""
        return self._api_call("DELETE", f"/api/libraries/{library_id}")

    def sync_from_file(self, config_file: str, dry_run: bool = False):
        """
        Sync libraries from a JSON configuration file.
        Creates missing libraries, updates existing ones.
        """
        try:
            with open(config_file, "r") as f:
                config = json.load(f)
        except Exception as e:
            raise Exception(f"Failed to load config file: {e}")

        if "libraries" not in config:
            raise ValueError('Config file must contain "libraries" array')

        desired_libraries = {lib["name"]: lib for lib in config["libraries"]}
        current_libraries = {lib["name"]: lib for lib in self.list_libraries()}

        print(f"\nSync Plan:", file=sys.stderr)
        print(f"  Desired libraries: {len(desired_libraries)}", file=sys.stderr)
        print(f"  Current libraries: {len(current_libraries)}", file=sys.stderr)

        if dry_run:
            print("\nDry-run mode - no changes will be made\n", file=sys.stderr)

        # Create or update libraries
        for name, desired in desired_libraries.items():
            folders = [{"fullPath": path} for path in desired["folders"]]
            media_type = desired.get("mediaType", "podcast")

            if name in current_libraries:
                current = current_libraries[name]

                # Check if folders need update
                current_folders = set(
                    f["fullPath"] for f in current.get("folders", [])
                )
                desired_folders = set(desired["folders"])
                needs_update = current_folders != desired_folders

                if needs_update:
                    print(f"  UPDATE: {name}", file=sys.stderr)
                    if not dry_run:
                        self.update_library(current["id"], folders=folders)
                else:
                    print(f"  OK: {name} (no changes)", file=sys.stderr)
            else:
                print(f"  CREATE: {name}", file=sys.stderr)
                if not dry_run:
                    self.create_library(
                        name=name, folders=folders, media_type=media_type
                    )

        if dry_run:
            print("\nDry-run complete - no changes made.", file=sys.stderr)
        else:
            print("\nSync complete!", file=sys.stderr)


def cmd_list(args, client):
    """List all libraries."""
    try:
        libraries = client.list_libraries()
        if args.output_format == "json":
            print(json.dumps(libraries, indent=2))
        else:
            print("Libraries:")
            for library in libraries:
                print(f"  {library['id']}: {library['name']} ({library['mediaType']})")
                if "folders" in library and library["folders"]:
                    print("  Folders:")
                    for folder in library["folders"]:
                        print(f"    - {folder['fullPath']}")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_create(args, client):
    """Create a new library."""
    try:
        folders = [{"fullPath": path} for path in args.folders]
        library = client.create_library(args.name, folders, args.media_type)
        print(f"Created library: {library['id']}")
        print(json.dumps(library, indent=2))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_sync(args, client):
    """Sync libraries from configuration file."""
    try:
        client.sync_from_file(args.config_file, dry_run=args.dry_run)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Audiobookshelf library management tool"
    )

    subparsers = parser.add_subparsers(
        dest="command", required=True, help="Command to execute"
    )

    # List command
    list_parser = subparsers.add_parser("list", help="List all libraries")
    list_parser.add_argument("--base-url", required=True, help="Audiobookshelf URL")
    list_parser.add_argument("--token", required=True, help="API token")
    list_parser.add_argument(
        "--output-format",
        choices=["table", "json"],
        default="table",
        help="Output format",
    )

    # Create command
    create_parser = subparsers.add_parser("create", help="Create a new library")
    create_parser.add_argument("--base-url", required=True, help="Audiobookshelf URL")
    create_parser.add_argument("--token", required=True, help="API token")
    create_parser.add_argument("--name", required=True, help="Library name")
    create_parser.add_argument(
        "--folders",
        nargs="+",
        required=True,
        help="Folder path(s) for the library",
    )
    create_parser.add_argument(
        "--media-type",
        choices=["book", "podcast"],
        default="podcast",
        help="Media type (default: podcast)",
    )

    # Sync command (declarative configuration)
    sync_parser = subparsers.add_parser(
        "sync", help="Sync libraries from configuration file"
    )
    sync_parser.add_argument("--base-url", required=True, help="Audiobookshelf URL")
    sync_parser.add_argument("--token", required=True, help="API token")
    sync_parser.add_argument(
        "--config-file", required=True, help="JSON configuration file"
    )
    sync_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without making changes",
    )

    args = parser.parse_args()

    client = AudiobookshelfClient(args.base_url, args.token)

    if args.command == "list":
        cmd_list(args, client)
    elif args.command == "create":
        cmd_create(args, client)
    elif args.command == "sync":
        cmd_sync(args, client)


if __name__ == "__main__":
    main()
