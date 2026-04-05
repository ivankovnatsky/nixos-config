"""Audiobookshelf API client and configuration."""

import json
import time
import urllib.request
import urllib.error
from pathlib import Path

import click

SOPS_SECRETS = {
    "ABS_API_KEY": "audiobookshelf-api-token",
    "ABS_URL": "audiobookshelf-url",
}

# Constants for common values
DEFAULT_ABS_URL = "http://localhost:13378"
DEFAULT_LIBRARY_NAME = "Podcasts"  # Library name to use by default


def _read_secret(name: str) -> str | None:
    """Read secret from sops-nix file."""
    sops_name = SOPS_SECRETS.get(name)
    if sops_name:
        sops_path = Path.home() / ".config/sops-nix/secrets" / sops_name
        try:
            return sops_path.read_text().strip()
        except OSError:
            pass
    return None


class AudiobookshelfClient:
    """Client for interacting with the Audiobookshelf API."""

    def __init__(self, api_key, base_url="http://localhost:13378"):
        """Initialize the client with API key and base URL."""
        self.api_key = api_key
        self.base_url = base_url.rstrip("/")

    def make_request(self, method, endpoint, data=None, files=None):
        """Make an HTTP request to the Audiobookshelf API."""
        url = f"{self.base_url}{endpoint}"
        headers = {"Authorization": f"Bearer {self.api_key}"}

        try:
            if files:
                # Handle file uploads with multipart/form-data (required for file uploads)
                boundary = "----boundary" + str(int(time.time()))
                headers["Content-Type"] = f"multipart/form-data; boundary={boundary}"

                # Create multipart body
                body = []

                # Add regular form fields
                if data:  # Check that data is not None before iterating
                    for key, value in data.items():
                        body.append(f"--{boundary}".encode())
                        body.append(
                            f'Content-Disposition: form-data; name="{key}"'.encode()
                        )
                        body.append(b"")
                        body.append(str(value).encode())

                # Add file as '0' parameter (matching curl's -F 0=@file.mp3 format)
                for i, (file_path, file_name) in enumerate(files.items()):
                    body.append(f"--{boundary}".encode())
                    body.append(
                        f'Content-Disposition: form-data; name="{i}"; filename="{file_name}"'.encode()
                    )
                    body.append(b"Content-Type: application/octet-stream")
                    body.append(b"")

                    with open(file_path, "rb") as file:
                        body.append(file.read())

                # Close the multipart body
                body.append(f"--{boundary}--".encode())
                body.append(b"")

                # Join with CRLF as per HTTP spec
                data = b"\r\n".join(body)
                request = urllib.request.Request(
                    url, data=data, headers=headers, method=method
                )

            elif data:
                # For regular JSON requests
                headers["Content-Type"] = "application/json"
                json_data = json.dumps(data).encode("utf-8")
                request = urllib.request.Request(
                    url, data=json_data, headers=headers, method=method
                )
            else:
                # Simple GET request
                request = urllib.request.Request(url, headers=headers, method=method)

            # Send the request and handle the response
            with urllib.request.urlopen(request) as response:
                response_data = response.read().decode("utf-8")
                if not response_data:
                    return None

                try:
                    return json.loads(response_data)
                except json.JSONDecodeError:
                    return response_data

        except urllib.error.HTTPError as e:
            # Handle HTTP errors (4xx, 5xx)
            # Don't print 404 errors for progress endpoints - item might not have progress
            if e.code == 404 and "/progress/" in url:
                return None

            error_message = e.read().decode("utf-8")
            try:
                error_data = json.loads(error_message)
                click.echo(f"Error: {error_data.get('error', error_message)}")
            except json.JSONDecodeError:
                click.echo(f"HTTP Error: {e.code} - {error_message}")
            return None
        except urllib.error.URLError as e:
            click.echo(f"URL Error: {e.reason}")
            return None
        except Exception as e:
            click.echo(f"Error: {str(e)}")
            return None

    def get_libraries(self):
        """Get all available libraries."""
        return self.make_request("GET", "/api/libraries")

    def get_library(self, library_name=None):
        """Get library ID and folder ID. If no name provided, returns first library.

        Args:
            library_name: Name of the library to find (optional, defaults to first library)

        Returns:
            Tuple of (library_id, folder_id) or (None, None) if not found
        """
        libraries_data = self.get_libraries()
        if not libraries_data or "libraries" not in libraries_data:
            return None, None

        libraries = libraries_data["libraries"]
        if not libraries:
            return None, None

        # If no name provided, use first library
        if library_name is None:
            library = libraries[0]
        else:
            # Find library by name
            library = None
            for lib in libraries:
                if lib["name"] == library_name:
                    library = lib
                    break

            if library is None:
                return None, None

        library_id = library["id"]

        # Get the first folder in the library
        if library.get("folders") and len(library["folders"]) > 0:
            folder_id = library["folders"][0]["id"]
            return library_id, folder_id

        return library_id, None

    def get_library_items(self, library_id):
        """Get all items in a library."""
        return self.make_request("GET", f"/api/libraries/{library_id}/items")

    def get_item_progress(self, item_id, episode_id=None):
        """Get progress information for a specific item."""
        if episode_id:
            return self.make_request("GET", f"/api/me/progress/{item_id}/{episode_id}")
        else:
            return self.make_request("GET", f"/api/me/progress/{item_id}")

    def remove_item(self, item_id, hard_delete=True):
        """Remove an item from the library.

        Args:
            item_id: ID of the item to remove
            hard_delete: If True, permanently delete files from disk (default: True)
        """
        endpoint = f"/api/items/{item_id}"
        if hard_delete:
            endpoint += "?hard=1"
        return self.make_request("DELETE", endpoint)

    def upload_file(self, file_path, library_name_or_id, title=None, folder_id=None):
        """Upload a file to a specific library.

        Args:
            file_path: Path to the file to upload
            library_name_or_id: Library name (e.g., "Podcasts") or ID to upload to
            title: Title for the media (optional, defaults to filename)
            folder_id: Folder ID to upload to (optional, will auto-detect if not provided)
        """
        file_path = Path(file_path)
        if not file_path.exists():
            click.echo(f"Error: File '{file_path}' does not exist.")
            return None

        title = title or file_path.stem

        # Determine if library_name_or_id is a name or ID
        # IDs are UUIDs with dashes, names typically don't have this format
        if "-" in library_name_or_id and len(library_name_or_id) > 30:
            # Looks like an ID
            library_id = library_name_or_id
            if not folder_id:
                click.echo(
                    "Warning: Library ID provided without folder ID, upload may fail"
                )
                click.echo(
                    "Consider using library name instead for automatic folder detection"
                )
        else:
            # Assume it's a library name, look it up
            library_id, detected_folder_id = self.get_library(library_name_or_id)
            if not library_id:
                click.echo(f"Error: Library '{library_name_or_id}' not found.")
                return None
            if not folder_id:
                folder_id = detected_folder_id

        if not folder_id:
            click.echo("Error: Could not determine folder ID for upload.")
            return None

        # Use required parameters
        data = {
            "title": title,
            "library": library_id,
            "folder": folder_id,
        }

        # File will be uploaded as "0" parameter
        files = {str(file_path): file_path.name}

        click.echo(f"Uploading to library ID: {library_id}")
        click.echo(f"Using folder ID: {folder_id}")
        click.echo(f"File: {file_path}")
        click.echo(f"Title: {title}")

        # Make the API request
        return self.make_request("POST", "/api/upload", data=data, files=files)
