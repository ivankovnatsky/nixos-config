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

            # Try to parse JSON, but accept plain text responses for successful requests
            try:
                return response.json()
            except ValueError:
                # Some endpoints return plain text (e.g., "OK") for success
                if response.text.strip() in ("OK", "Success"):
                    return {"success": True, "message": response.text.strip()}
                # For other non-JSON responses, log and return text
                print(f"DEBUG: Non-JSON response: {response.text[:200]}", file=sys.stderr)
                return {"success": True, "message": response.text}
        except requests.exceptions.RequestException as e:
            raise Exception(f"Network error: {e}")

    def list_libraries(self):
        """List all libraries."""
        data = self._api_call("GET", "/api/libraries")
        return data.get("libraries", [])

    def create_library(self, name: str, folders: list, media_type: str = "podcast", provider: str = "itunes"):
        """Create a new library."""
        data = {
            "name": name,
            "folders": folders,
            "mediaType": media_type,
            "provider": provider,
        }
        return self._api_call("POST", "/api/libraries", data=data)

    def update_library(self, library_id: str, name: str = None, folders: list = None, provider: str = None):
        """Update an existing library."""
        data = {}
        if name is not None:
            data["name"] = name
        if folders is not None:
            data["folders"] = folders
        if provider is not None:
            data["provider"] = provider

        return self._api_call("PATCH", f"/api/libraries/{library_id}", data=data)

    def delete_library(self, library_id: str):
        """Delete a library."""
        return self._api_call("DELETE", f"/api/libraries/{library_id}")

    def list_users(self):
        """List all users."""
        data = self._api_call("GET", "/api/users")
        return data.get("users", [])

    def create_user(self, username: str, password: str, user_type: str = "user", libraries: list = None):
        """Create a new user."""
        data = {
            "username": username,
            "password": password,
            "type": user_type,
        }
        if libraries:
            data["libraries"] = libraries
        return self._api_call("POST", "/api/users", data=data)

    def update_user(self, user_id: str, username: str = None, user_type: str = None, libraries: list = None):
        """Update an existing user."""
        data = {}
        if username is not None:
            data["username"] = username
        if user_type is not None:
            data["type"] = user_type
        if libraries is not None:
            data["libraries"] = libraries

        return self._api_call("PATCH", f"/api/users/{user_id}", data=data)

    def delete_user(self, user_id: str):
        """Delete a user."""
        return self._api_call("DELETE", f"/api/users/{user_id}")

    def parse_opml(self, opml_text: str):
        """Parse OPML text and return feed URLs."""
        data = {"opmlText": opml_text}
        return self._api_call("POST", "/api/podcasts/opml/parse", data=data)

    def bulk_create_from_opml_feeds(self, feeds: list, library_id: str, folder_id: str, auto_download: bool = True):
        """Bulk create podcasts from OPML feed URLs."""
        data = {
            "feeds": feeds,
            "libraryId": library_id,
            "folderId": folder_id,
            "autoDownloadEpisodes": auto_download
        }
        return self._api_call("POST", "/api/podcasts/opml/create", data=data)

    def get_library_podcasts(self, library_id: str):
        """Get all podcast items in a library."""
        data = self._api_call("GET", f"/api/libraries/{library_id}/items")
        return data.get("results", [])

    def get_library_by_name(self, library_name: str):
        """Get library ID and folder ID by library name.

        Returns:
            Tuple of (library_id, folder_id) or (None, None) if not found
        """
        libraries_data = self.list_libraries()

        for library in libraries_data:
            if library["name"] == library_name:
                library_id = library["id"]
                # Get first folder ID
                if library.get("folders") and len(library["folders"]) > 0:
                    folder_id = library["folders"][0]["id"]
                    return library_id, folder_id
                return library_id, None

        return None, None

    def sync_from_file(self, config_file: str, dry_run: bool = False, opml_url: str = None, opml_library_name: str = "Podcasts", opml_auto_download: bool = True):
        """
        Sync libraries and users from a JSON configuration file.
        Creates missing items, updates existing ones.
        Optionally syncs OPML feeds if opml_url is provided.
        """
        try:
            with open(config_file, "r") as f:
                config = json.load(f)
        except Exception as e:
            raise Exception(f"Failed to load config file: {e}")

        # Sync libraries if present
        if "libraries" in config:
            self._sync_libraries(config["libraries"], dry_run)

        # Sync users if present
        if "users" in config:
            self._sync_users(config["users"], dry_run)

        # Sync OPML if URL provided (library name defaults to "Podcasts")
        if opml_url:
            self._sync_opml(opml_url, opml_library_name, opml_auto_download, dry_run)

    def _sync_libraries(self, libraries_config: list, dry_run: bool = False):
        """Sync libraries from configuration."""
        desired_libraries = {lib["name"]: lib for lib in libraries_config}
        current_libraries = {lib["name"]: lib for lib in self.list_libraries()}

        print("", file=sys.stderr)
        print("Sync Plan:", file=sys.stderr)
        print(f"  Desired libraries: {len(desired_libraries)}", file=sys.stderr)
        print(f"  Current libraries: {len(current_libraries)}", file=sys.stderr)

        if dry_run:
            print("", file=sys.stderr)
            print("Dry-run mode - no changes will be made", file=sys.stderr)
            print("", file=sys.stderr)

        # Create or update libraries
        for name, desired in desired_libraries.items():
            folders = [{"fullPath": path} for path in desired["folders"]]
            media_type = desired.get("mediaType", "podcast")
            provider = desired.get("provider", "itunes")

            if name in current_libraries:
                current = current_libraries[name]

                # Check if folders need update
                current_folders = set(
                    f["fullPath"] for f in current.get("folders", [])
                )
                desired_folders = set(desired["folders"])
                folders_changed = current_folders != desired_folders

                # Check if provider needs update
                current_provider = current.get("provider", "")
                provider_changed = current_provider != provider

                needs_update = folders_changed or provider_changed

                if needs_update:
                    update_parts = []
                    if folders_changed:
                        update_parts.append("folders")
                    if provider_changed:
                        update_parts.append(f"provider: {current_provider} -> {provider}")

                    print(f"  UPDATE: {name} ({', '.join(update_parts)})", file=sys.stderr)
                    if not dry_run:
                        self.update_library(
                            current["id"],
                            folders=folders if folders_changed else None,
                            provider=provider if provider_changed else None
                        )
                else:
                    print(f"  OK: {name} (no changes)", file=sys.stderr)
            else:
                print(f"  CREATE: {name}", file=sys.stderr)
                if not dry_run:
                    self.create_library(
                        name=name, folders=folders, media_type=media_type, provider=provider
                    )

        if dry_run:
            print("", file=sys.stderr)
            print("Library sync dry-run complete - no changes made.", file=sys.stderr)
        else:
            print("", file=sys.stderr)
            print("Library sync complete!", file=sys.stderr)

    def _sync_users(self, users_config: list, dry_run: bool = False):
        """Sync users from configuration."""
        desired_users = {user["username"]: user for user in users_config}
        current_users = {user["username"]: user for user in self.list_users()}

        print("", file=sys.stderr)
        print("User Sync Plan:", file=sys.stderr)
        print(f"  Desired users: {len(desired_users)}", file=sys.stderr)
        print(f"  Current users: {len(current_users)}", file=sys.stderr)

        if dry_run:
            print("", file=sys.stderr)
            print("Dry-run mode - no changes will be made", file=sys.stderr)
            print("", file=sys.stderr)

        # Create or update users
        for username, desired in desired_users.items():
            user_type = desired.get("type", "user")
            libraries = desired.get("libraries", [])
            password = desired.get("password")

            if username in current_users:
                current = current_users[username]

                # Check if type or libraries need update
                current_type = current.get("type", "user")
                current_libraries = current.get("libraries", [])
                type_changed = current_type != user_type
                libraries_changed = set(current_libraries) != set(libraries)

                needs_update = type_changed or libraries_changed

                if needs_update:
                    update_parts = []
                    if type_changed:
                        update_parts.append(f"type: {current_type} -> {user_type}")
                    if libraries_changed:
                        update_parts.append("libraries")

                    print(f"  UPDATE: {username} ({', '.join(update_parts)})", file=sys.stderr)
                    if not dry_run:
                        self.update_user(
                            current["id"],
                            user_type=user_type if type_changed else None,
                            libraries=libraries if libraries_changed else None
                        )
                else:
                    print(f"  OK: {username} (no changes)", file=sys.stderr)
            else:
                if not password:
                    print(f"  SKIP: {username} (no password provided for new user)", file=sys.stderr)
                    continue

                print(f"  CREATE: {username}", file=sys.stderr)
                if not dry_run:
                    self.create_user(
                        username=username,
                        password=password,
                        user_type=user_type,
                        libraries=libraries
                    )

        if dry_run:
            print("", file=sys.stderr)
            print("User sync dry-run complete - no changes made.", file=sys.stderr)
        else:
            print("", file=sys.stderr)
            print("User sync complete!", file=sys.stderr)

    def _sync_opml(self, opml_url: str, library_name: str, auto_download: bool = True, dry_run: bool = False):
        """Sync podcasts from OPML URL."""
        try:
            # Resolve library name to ID/folder
            print(f"Resolving library name '{library_name}'...", file=sys.stderr)
            library_id, folder_id = self.get_library_by_name(library_name)
            if not library_id:
                print(f"Error: Library '{library_name}' not found", file=sys.stderr)
                return
            if not folder_id:
                print(f"Error: No folders found in library '{library_name}'", file=sys.stderr)
                return
            print(f"Resolved to library ID: {library_id}, folder ID: {folder_id}", file=sys.stderr)

            # Fetch OPML from URL
            print(f"Fetching OPML from {opml_url}...", file=sys.stderr)
            response = requests.get(opml_url, timeout=30)
            response.raise_for_status()
            opml_text = response.text

            # Parse OPML to get feed URLs
            print("Parsing OPML...", file=sys.stderr)
            parsed = self.parse_opml(opml_text)
            feeds = parsed.get("feeds", [])

            if not feeds:
                print("No feeds found in OPML", file=sys.stderr)
                return

            print(f"Found {len(feeds)} feeds in OPML", file=sys.stderr)

            # Get existing podcasts in library
            print("Fetching existing podcasts from library...", file=sys.stderr)
            existing_podcasts = self.get_library_podcasts(library_id)
            existing_feed_urls = set()
            for podcast in existing_podcasts:
                feed_url = podcast.get("media", {}).get("metadata", {}).get("feedUrl")
                if feed_url:
                    existing_feed_urls.add(feed_url)

            print(f"Found {len(existing_podcasts)} existing podcasts in library", file=sys.stderr)

            # Extract feed URLs from OPML feeds (API returns dict objects with 'feedUrl' key)
            opml_feed_urls = []
            for feed in feeds:
                feed_url = feed.get("feedUrl") if isinstance(feed, dict) else feed
                if feed_url:
                    opml_feed_urls.append(feed_url)

            # Filter out feeds that already exist
            new_feeds = [feed_url for feed_url in opml_feed_urls if feed_url not in existing_feed_urls]

            print("", file=sys.stderr)
            print(f"OPML Sync summary:", file=sys.stderr)
            print(f"  Total feeds in OPML: {len(opml_feed_urls)}", file=sys.stderr)
            print(f"  Already imported: {len(opml_feed_urls) - len(new_feeds)}", file=sys.stderr)
            print(f"  New feeds to import: {len(new_feeds)}", file=sys.stderr)

            if new_feeds:
                print("", file=sys.stderr)
                print("New feeds to import:", file=sys.stderr)
                for feed in new_feeds:
                    print(f"  - {feed}", file=sys.stderr)

            if not new_feeds:
                print("\nNo new feeds to import - already up to date!", file=sys.stderr)
                return

            if dry_run:
                print("\nDry-run mode - no changes will be made", file=sys.stderr)
                return

            # Bulk create podcasts from new feeds only
            print(f"\nCreating {len(new_feeds)} new podcasts in library {library_id}, folder {folder_id}...", file=sys.stderr)
            print(f"Auto-download episodes: {auto_download}", file=sys.stderr)

            self.bulk_create_from_opml_feeds(
                feeds=new_feeds,
                library_id=library_id,
                folder_id=folder_id,
                auto_download=auto_download
            )

            print("", file=sys.stderr)
            print("OPML sync request sent successfully!", file=sys.stderr)
            print("Note: Podcast creation happens asynchronously. Check Audiobookshelf logs if podcasts don't appear.", file=sys.stderr)

        except requests.exceptions.RequestException as e:
            print(f"Error fetching OPML: {e}", file=sys.stderr)
            raise
        except Exception as e:
            print(f"Error syncing OPML: {e}", file=sys.stderr)
            raise


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
        client.sync_from_file(
            args.config_file,
            dry_run=args.dry_run,
            opml_url=getattr(args, 'opml_url', None),
            opml_library_name=getattr(args, 'opml_library_name', None),
            opml_auto_download=getattr(args, 'opml_auto_download', True)
        )
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_sync_opml(args, client):
    """Sync podcasts from Podsync OPML URL."""
    try:
        # Get library name (defaults to "Podcasts")
        library_name = args.library_name

        # Warn about deprecated library_id/folder_id
        if hasattr(args, 'library_id') and args.library_id:
            print("Warning: --library-id is deprecated, use --library-name instead", file=sys.stderr)
        if hasattr(args, 'folder_id') and args.folder_id:
            print("Warning: --folder-id is deprecated, use --library-name instead", file=sys.stderr)

        # Call shared OPML sync logic
        client._sync_opml(
            opml_url=args.opml_url,
            library_name=library_name,
            auto_download=args.auto_download,
            dry_run=args.dry_run
        )

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
    sync_parser.add_argument("--opml-url", help="Optional: Podsync OPML URL to sync")
    sync_parser.add_argument("--opml-library-name", default="Podcasts", help="Optional: Target library name for OPML sync (default: Podcasts)")
    sync_parser.add_argument(
        "--opml-auto-download",
        action="store_true",
        default=True,
        help="Enable automatic episode downloads for OPML sync (default: true)",
    )

    # Sync OPML command (from Podsync)
    sync_opml_parser = subparsers.add_parser(
        "sync-opml", help="Sync podcasts from Podsync OPML URL"
    )
    sync_opml_parser.add_argument("--base-url", required=True, help="Audiobookshelf URL")
    sync_opml_parser.add_argument("--token", required=True, help="API token")
    sync_opml_parser.add_argument("--opml-url", required=True, help="Podsync OPML URL")
    sync_opml_parser.add_argument("--library-name", default="Podcasts", help="Target library name (auto-detects ID and folder, default: Podcasts)")
    sync_opml_parser.add_argument("--library-id", help="Target library ID (use with --folder-id, deprecated)")
    sync_opml_parser.add_argument("--folder-id", help="Target folder ID (use with --library-id, deprecated)")
    sync_opml_parser.add_argument(
        "--auto-download",
        action="store_true",
        default=True,
        help="Enable automatic episode downloads (default: true)",
    )
    sync_opml_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be synced without making changes",
    )

    args = parser.parse_args()

    client = AudiobookshelfClient(args.base_url, args.token)

    if args.command == "list":
        cmd_list(args, client)
    elif args.command == "create":
        cmd_create(args, client)
    elif args.command == "sync":
        cmd_sync(args, client)
    elif args.command == "sync-opml":
        cmd_sync_opml(args, client)


if __name__ == "__main__":
    main()
