#!/usr/bin/env python3
"""
Audiobookshelf library management tool.
Declarative library configuration via sync command.
"""

import sys
import json
import requests
import click

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
                    click.echo(f"DEBUG: Error response: {error_data}", err=True)
                    message = error_data.get("error", "Unknown error")
                    raise Exception(
                        f"API error: {message} (Status: {response.status_code})"
                    )
                except ValueError:
                    click.echo(f"DEBUG: Response text: {response.text}", err=True)
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
                click.echo(f"DEBUG: Non-JSON response: {response.text[:200]}", err=True)
                return {"success": True, "message": response.text}
        except requests.exceptions.RequestException as e:
            raise Exception(f"Network error: {e}")

    def list_libraries(self):
        """List all libraries."""
        data = self._api_call("GET", "/api/libraries")
        return data.get("libraries", [])

    def create_library(
        self,
        name: str,
        folders: list,
        media_type: str = "podcast",
        provider: str = "itunes",
    ):
        """Create a new library."""
        data = {
            "name": name,
            "folders": folders,
            "mediaType": media_type,
            "provider": provider,
        }
        return self._api_call("POST", "/api/libraries", data=data)

    def update_library(
        self,
        library_id: str,
        name: str = None,
        folders: list = None,
        provider: str = None,
    ):
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

    def create_user(
        self,
        username: str,
        password: str,
        user_type: str = "user",
        libraries: list = None,
    ):
        """Create a new user."""
        data = {
            "username": username,
            "password": password,
            "type": user_type,
        }
        if libraries:
            data["libraries"] = libraries
        return self._api_call("POST", "/api/users", data=data)

    def update_user(
        self,
        user_id: str,
        username: str = None,
        user_type: str = None,
        libraries: list = None,
    ):
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

    def bulk_create_from_opml_feeds(
        self, feeds: list, library_id: str, folder_id: str, auto_download: bool = True
    ):
        """Bulk create podcasts from OPML feed URLs."""
        data = {
            "feeds": feeds,
            "libraryId": library_id,
            "folderId": folder_id,
            "autoDownloadEpisodes": auto_download,
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

    def sync_from_file(self, config_file: str, dry_run: bool = False):
        """
        Sync libraries and users from a JSON configuration file.
        Creates missing items, updates existing ones.
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

    def _sync_libraries(self, libraries_config: list, dry_run: bool = False):
        """Sync libraries from configuration."""
        desired_libraries = {lib["name"]: lib for lib in libraries_config}
        current_libraries = {lib["name"]: lib for lib in self.list_libraries()}

        click.echo("", err=True)
        click.echo("Sync Plan:", err=True)
        click.echo(f"  Desired libraries: {len(desired_libraries)}", err=True)
        click.echo(f"  Current libraries: {len(current_libraries)}", err=True)

        if dry_run:
            click.echo("", err=True)
            click.echo("Dry-run mode - no changes will be made", err=True)
            click.echo("", err=True)

        # Create or update libraries
        for name, desired in desired_libraries.items():
            folders = [{"fullPath": path} for path in desired["folders"]]
            media_type = desired.get("mediaType", "podcast")
            provider = desired.get("provider", "itunes")

            if name in current_libraries:
                current = current_libraries[name]

                # Check if folders need update
                current_folders = set(f["fullPath"] for f in current.get("folders", []))
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
                        update_parts.append(
                            f"provider: {current_provider} -> {provider}"
                        )

                    click.echo(
                        f"  UPDATE: {name} ({', '.join(update_parts)})", err=True
                    )
                    if not dry_run:
                        self.update_library(
                            current["id"],
                            folders=folders if folders_changed else None,
                            provider=provider if provider_changed else None,
                        )
                else:
                    click.echo(f"  OK: {name} (no changes)", err=True)
            else:
                click.echo(f"  CREATE: {name}", err=True)
                if not dry_run:
                    self.create_library(
                        name=name,
                        folders=folders,
                        media_type=media_type,
                        provider=provider,
                    )

        if dry_run:
            click.echo("", err=True)
            click.echo("Library sync dry-run complete - no changes made.", err=True)
        else:
            click.echo("", err=True)
            click.echo("Library sync complete!", err=True)

    def _sync_users(self, users_config: list, dry_run: bool = False):
        """Sync users from configuration."""
        desired_users = {user["username"]: user for user in users_config}
        current_users = {user["username"]: user for user in self.list_users()}

        click.echo("", err=True)
        click.echo("User Sync Plan:", err=True)
        click.echo(f"  Desired users: {len(desired_users)}", err=True)
        click.echo(f"  Current users: {len(current_users)}", err=True)

        if dry_run:
            click.echo("", err=True)
            click.echo("Dry-run mode - no changes will be made", err=True)
            click.echo("", err=True)

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

                    click.echo(
                        f"  UPDATE: {username} ({', '.join(update_parts)})",
                        err=True,
                    )
                    if not dry_run:
                        self.update_user(
                            current["id"],
                            user_type=user_type if type_changed else None,
                            libraries=libraries if libraries_changed else None,
                        )
                else:
                    click.echo(f"  OK: {username} (no changes)", err=True)
            else:
                if not password:
                    click.echo(
                        f"  SKIP: {username} (no password provided for new user)",
                        err=True,
                    )
                    continue

                click.echo(f"  CREATE: {username}", err=True)
                if not dry_run:
                    self.create_user(
                        username=username,
                        password=password,
                        user_type=user_type,
                        libraries=libraries,
                    )

        if dry_run:
            click.echo("", err=True)
            click.echo("User sync dry-run complete - no changes made.", err=True)
        else:
            click.echo("", err=True)
            click.echo("User sync complete!", err=True)

    def _sync_opml(
        self,
        opml_url: str,
        library_name: str,
        auto_download: bool = True,
        dry_run: bool = False,
    ):
        """Sync podcasts from OPML URL."""
        try:
            # Resolve library name to ID/folder
            click.echo(f"Resolving library name '{library_name}'...", err=True)
            library_id, folder_id = self.get_library_by_name(library_name)
            if not library_id:
                click.echo(f"Error: Library '{library_name}' not found", err=True)
                return
            if not folder_id:
                click.echo(
                    f"Error: No folders found in library '{library_name}'",
                    err=True,
                )
                return
            click.echo(
                f"Resolved to library ID: {library_id}, folder ID: {folder_id}",
                err=True,
            )

            # Fetch OPML from URL
            click.echo(f"Fetching OPML from {opml_url}...", err=True)
            response = requests.get(opml_url, timeout=30)
            response.raise_for_status()
            opml_text = response.text

            # Parse OPML to get feed URLs
            click.echo("Parsing OPML...", err=True)
            parsed = self.parse_opml(opml_text)
            feeds = parsed.get("feeds", [])

            if not feeds:
                click.echo("No feeds found in OPML", err=True)
                return

            click.echo(f"Found {len(feeds)} feeds in OPML", err=True)

            # Get existing podcasts in library
            click.echo("Fetching existing podcasts from library...", err=True)
            existing_podcasts = self.get_library_podcasts(library_id)
            existing_feed_urls = set()
            for podcast in existing_podcasts:
                feed_url = podcast.get("media", {}).get("metadata", {}).get("feedUrl")
                if feed_url:
                    existing_feed_urls.add(feed_url)

            click.echo(
                f"Found {len(existing_podcasts)} existing podcasts in library",
                err=True,
            )

            # Extract feed URLs from OPML feeds (API returns dict objects with 'feedUrl' key)
            opml_feed_urls = []
            for feed in feeds:
                feed_url = feed.get("feedUrl") if isinstance(feed, dict) else feed
                if feed_url:
                    opml_feed_urls.append(feed_url)

            # Filter out feeds that already exist
            new_feeds = [
                feed_url
                for feed_url in opml_feed_urls
                if feed_url not in existing_feed_urls
            ]

            click.echo("", err=True)
            click.echo("OPML Sync summary:", err=True)
            click.echo(f"  Total feeds in OPML: {len(opml_feed_urls)}", err=True)
            click.echo(
                f"  Already imported: {len(opml_feed_urls) - len(new_feeds)}",
                err=True,
            )
            click.echo(f"  New feeds to import: {len(new_feeds)}", err=True)

            if new_feeds:
                click.echo("", err=True)
                click.echo("New feeds to import:", err=True)
                for feed in new_feeds:
                    click.echo(f"  - {feed}", err=True)

            if not new_feeds:
                click.echo("\nNo new feeds to import - already up to date!", err=True)
                return

            if dry_run:
                click.echo("\nDry-run mode - no changes will be made", err=True)
                return

            # Bulk create podcasts from new feeds only
            click.echo(
                f"\nCreating {len(new_feeds)} new podcasts in library {library_id}, folder {folder_id}...",
                err=True,
            )
            click.echo(f"Auto-download episodes: {auto_download}", err=True)

            self.bulk_create_from_opml_feeds(
                feeds=new_feeds,
                library_id=library_id,
                folder_id=folder_id,
                auto_download=auto_download,
            )

            click.echo("", err=True)
            click.echo("OPML sync request sent successfully!", err=True)
            click.echo(
                "Note: Podcast creation happens asynchronously. Check Audiobookshelf logs if podcasts don't appear.",
                err=True,
            )

        except requests.exceptions.RequestException as e:
            click.echo(f"Error fetching OPML: {e}", err=True)
            raise
        except Exception as e:
            click.echo(f"Error syncing OPML: {e}", err=True)
            raise


@click.group()
def cli():
    """Audiobookshelf library management tool."""


@cli.command("list")
@click.option("--base-url", required=True, help="Audiobookshelf URL")
@click.option("--token", required=True, help="API token")
@click.option(
    "--output-format",
    type=click.Choice(["table", "json"]),
    default="table",
    help="Output format",
)
def cmd_list(base_url, token, output_format):
    """List all libraries."""
    client = AudiobookshelfClient(base_url, token)
    try:
        libraries = client.list_libraries()
        if output_format == "json":
            click.echo(json.dumps(libraries, indent=2))
        else:
            click.echo("Libraries:")
            for library in libraries:
                click.echo(
                    f"  {library['id']}: {library['name']} ({library['mediaType']})"
                )
                if "folders" in library and library["folders"]:
                    click.echo("  Folders:")
                    for folder in library["folders"]:
                        click.echo(f"    - {folder['fullPath']}")
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


@cli.command("create")
@click.option("--base-url", required=True, help="Audiobookshelf URL")
@click.option("--token", required=True, help="API token")
@click.option("--name", required=True, help="Library name")
@click.option(
    "--folders",
    multiple=True,
    required=True,
    help="Folder path(s) for the library (repeat for multiple: --folders /a --folders /b)",
)
@click.option(
    "--media-type",
    type=click.Choice(["book", "podcast"]),
    default="podcast",
    help="Media type (default: podcast)",
)
def cmd_create(base_url, token, name, folders, media_type):
    """Create a new library."""
    client = AudiobookshelfClient(base_url, token)
    try:
        folder_list = [{"fullPath": path} for path in folders]
        library = client.create_library(name, folder_list, media_type)
        click.echo(f"Created library: {library['id']}")
        click.echo(json.dumps(library, indent=2))
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


@cli.command("sync")
@click.option("--base-url", required=True, help="Audiobookshelf URL")
@click.option("--token", required=True, help="API token")
@click.option("--config-file", required=True, help="JSON configuration file")
@click.option(
    "--dry-run",
    is_flag=True,
    help="Show what would be changed without making changes",
)
def cmd_sync(base_url, token, config_file, dry_run):
    """Sync libraries from configuration file."""
    client = AudiobookshelfClient(base_url, token)
    try:
        client.sync_from_file(config_file, dry_run=dry_run)
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


@cli.command("sync-opml")
@click.option("--base-url", required=True, help="Audiobookshelf URL")
@click.option("--token", required=True, help="API token")
@click.option("--opml-url", required=True, help="Podsync OPML URL")
@click.option(
    "--library-name",
    default="Podcasts",
    help="Target library name (auto-detects ID and folder, default: Podcasts)",
)
@click.option(
    "--library-id",
    default=None,
    help="Target library ID (use with --folder-id, deprecated)",
)
@click.option(
    "--folder-id",
    default=None,
    help="Target folder ID (use with --library-id, deprecated)",
)
@click.option(
    "--auto-download",
    is_flag=True,
    default=True,
    help="Enable automatic episode downloads (default: true)",
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Show what would be synced without making changes",
)
def cmd_sync_opml(
    base_url,
    token,
    opml_url,
    library_name,
    library_id,
    folder_id,
    auto_download,
    dry_run,
):
    """Sync podcasts from Podsync OPML URL."""
    client = AudiobookshelfClient(base_url, token)
    try:
        # Warn about deprecated library_id/folder_id
        if library_id:
            click.echo(
                "Warning: --library-id is deprecated, use --library-name instead",
                err=True,
            )
        if folder_id:
            click.echo(
                "Warning: --folder-id is deprecated, use --library-name instead",
                err=True,
            )

        # Call shared OPML sync logic
        client._sync_opml(
            opml_url=opml_url,
            library_name=library_name,
            auto_download=auto_download,
            dry_run=dry_run,
        )

    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


def main():
    cli()


if __name__ == "__main__":
    main()
