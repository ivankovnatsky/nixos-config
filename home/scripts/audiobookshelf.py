#!/usr/bin/env python3
"""
Audiobookshelf CLI tool for interacting with the Audiobookshelf API.

https://api.audiobookshelf.org/
"""

import argparse
import json
import os
import sys
import urllib.request
import urllib.parse
import urllib.error
from pathlib import Path
import time

# Constants for common values
DEFAULT_ABS_URL = "http://localhost:13378"
DEFAULT_PODCASTS_LIBRARY_ID = (
    "db54da2c-dc16-4fdb-8dd4-5375ae98f738"  # Podcasts library ID
)
DEFAULT_PODCASTS_FOLDER_ID = (
    "fabf78a1-9d87-41a0-8b72-1007e7f10889"  # /storage/media/podcasts folder ID
)


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
            error_message = e.read().decode("utf-8")
            try:
                error_data = json.loads(error_message)
                print(f"Error: {error_data.get('error', error_message)}")
            except json.JSONDecodeError:
                print(f"HTTP Error: {e.code} - {error_message}")
            return None
        except urllib.error.URLError as e:
            print(f"URL Error: {e.reason}")
            return None
        except Exception as e:
            print(f"Error: {str(e)}")
            return None

    def get_libraries(self):
        """Get all available libraries."""
        return self.make_request("GET", "/api/libraries")

    def upload_file(self, file_path, library_id, title=None):
        """Upload a file to a specific library.

        Args:
            file_path: Path to the file to upload
            library_id: ID of the library to upload to
            title: Title for the media (optional, defaults to filename)
        """
        file_path = Path(file_path)
        if not file_path.exists():
            print(f"Error: File '{file_path}' does not exist.")
            return None

        title = title or file_path.stem

        # Use required parameters with the default folder ID
        data = {
            "title": title,
            "library": library_id,
            "folder": DEFAULT_PODCASTS_FOLDER_ID,  # Use the default podcasts folder ID
        }

        # File will be uploaded as "0" parameter
        files = {str(file_path): file_path.name}

        print(f"Uploading to library ID: {library_id}")
        print(f"Using folder ID: {DEFAULT_PODCASTS_FOLDER_ID}")
        print(f"File: {file_path}")
        print(f"Title: {title}")

        # Make the API request
        return self.make_request("POST", "/api/upload", data=data, files=files)


def upload_command(args, client):
    """Handle the upload command."""
    file_path = Path(args.file)

    if not file_path.exists():
        print(f"Error: File '{file_path}' does not exist.")
        return

    # Get filename without path or extension to use as title
    filename = file_path.stem

    # Upload file
    print(f"Uploading '{file_path}' to Audiobookshelf...")
    upload_response = client.upload_file(file_path, args.library_id, title=filename)

    if upload_response:
        print("Upload successful!")
        print(f"Response: {upload_response}")
    else:
        print("Upload failed. Please check your connection and API key.")


def libraries_command(client):
    """Handle the libraries command."""
    print(f"Fetching libraries from {client.base_url}...")

    libraries = client.get_libraries()

    if not libraries or "libraries" not in libraries:
        print("No libraries found or unable to retrieve libraries.")
        return

    print("\nAvailable Libraries:")
    print("-----------------")

    for library in libraries["libraries"]:
        print(f"ID: {library['id']}")
        print(f"Name: {library['name']}")
        print(f"Media Type: {library.get('mediaType', 'Unknown')}")

        # Display folders if available
        if "folders" in library and library["folders"]:
            print("Folders:")
            for folder in library["folders"]:
                print(f"  - ID: {folder['id']}")
                if "fullPath" in folder:
                    print(f"    Path: {folder['fullPath']}")

        print()


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="Interact with Audiobookshelf from the command line."
    )

    # Explicitly describe the command structure
    parser.usage = "%(prog)s COMMAND [options]"
    if parser.description:
        parser.description += (
            "\n\nCommands must be specified first, followed by their options."
        )
    else:
        parser.description = "Interact with Audiobookshelf from the command line.\n\nCommands must be specified first, followed by their options."

    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # Upload command
    upload_parser = subparsers.add_parser(
        "upload", help="Upload an audio file to Audiobookshelf"
    )
    upload_parser.add_argument(
        "--url",
        default=os.environ.get("ABS_URL", DEFAULT_ABS_URL),
        help=f"Audiobookshelf URL (default: {DEFAULT_ABS_URL} or ABS_URL env var)",
    )
    upload_parser.add_argument("--file", required=True, help="Audio file to upload")
    upload_parser.add_argument(
        "--library-id",
        default=DEFAULT_PODCASTS_LIBRARY_ID,
        help=f"Library ID (default: {DEFAULT_PODCASTS_LIBRARY_ID} - Podcasts library)",
    )

    # Libraries command
    libraries_parser = subparsers.add_parser(
        "libraries", help="List available libraries in Audiobookshelf"
    )
    libraries_parser.add_argument(
        "--url",
        default=os.environ.get("ABS_URL", DEFAULT_ABS_URL),
        help=f"Audiobookshelf URL (default: {DEFAULT_ABS_URL} or ABS_URL env var)",
    )

    # Handle case where no arguments are provided
    if len(sys.argv) == 1:
        parser.print_help()
        return 1

    # Make sure the first argument is a valid command
    valid_commands = ["upload", "libraries", "-h", "--help"]
    if sys.argv[1] not in valid_commands:
        print(f"Error: '{sys.argv[1]}' is not a recognized command.")
        print("Commands must come first, before any options.")
        print("\nAvailable commands: upload, libraries")
        print("\nUsage example:")
        print(
            "  audiobookshelf upload --url https://example.com --file file.mp3 --library-id ID"
        )
        print("  audiobookshelf libraries --url https://example.com")
        return 1

    args = parser.parse_args()

    # Check for API key
    api_key = os.environ.get("ABS_API_KEY")
    if not api_key:
        print("Error: Missing API key")
        print("Please set the ABS_API_KEY environment variable")
        return 1

    # Initialize client with URL from command arguments
    client = AudiobookshelfClient(api_key, args.url)

    # Handle commands
    if args.command == "upload":
        upload_command(args, client)
    elif args.command == "libraries":
        libraries_command(client)
    else:
        parser.print_help()

    return 0


if __name__ == "__main__":
    sys.exit(main())
