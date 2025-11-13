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
import tempfile
import subprocess
import glob
from datetime import datetime

# Constants for common values
DEFAULT_ABS_URL = "http://localhost:13378"
DEFAULT_LIBRARY_NAME = "Podcasts"  # Library name to use by default


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
            print(f"Error: File '{file_path}' does not exist.")
            return None

        title = title or file_path.stem

        # Determine if library_name_or_id is a name or ID
        # IDs are UUIDs with dashes, names typically don't have this format
        if "-" in library_name_or_id and len(library_name_or_id) > 30:
            # Looks like an ID
            library_id = library_name_or_id
            if not folder_id:
                print("Warning: Library ID provided without folder ID, upload may fail")
                print(
                    "Consider using library name instead for automatic folder detection"
                )
        else:
            # Assume it's a library name, look it up
            library_id, detected_folder_id = self.get_library(library_name_or_id)
            if not library_id:
                print(f"Error: Library '{library_name_or_id}' not found.")
                return None
            if not folder_id:
                folder_id = detected_folder_id

        if not folder_id:
            print("Error: Could not determine folder ID for upload.")
            return None

        # Use required parameters
        data = {
            "title": title,
            "library": library_id,
            "folder": folder_id,
        }

        # File will be uploaded as "0" parameter
        files = {str(file_path): file_path.name}

        print(f"Uploading to library ID: {library_id}")
        print(f"Using folder ID: {folder_id}")
        print(f"File: {file_path}")
        print(f"Title: {title}")

        # Make the API request
        return self.make_request("POST", "/api/upload", data=data, files=files)


def download_audio(url, output_dir=None):
    """Download audio from a URL using yt-dlp.

    Args:
        url: URL to download from
        output_dir: Directory to save the file to (default: current directory)

    Returns:
        Path to the downloaded MP3 file or None if failed
    """
    print(f"Downloading and extracting audio from {url}...")

    # Create a temporary directory if none provided
    if not output_dir:
        output_dir = os.getcwd()

    # Ensure the directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Change to the output directory
    original_dir = os.getcwd()
    os.chdir(output_dir)

    try:
        # Run yt-dlp command
        cmd = [
            "yt-dlp",
            "--extract-audio",
            "--audio-format",
            "mp3",
            "--postprocessor-args",
            "-ac 1 -ar 24000",
            url,
        ]

        subprocess.run(cmd, check=True, capture_output=True, text=True)

        # Find the generated MP3 file
        mp3_files = glob.glob(os.path.join(output_dir, "*.mp3"))

        if not mp3_files:
            print("Error: No MP3 file was generated.")
            return None

        # Return the path to the first MP3 file found
        return mp3_files[0]

    except subprocess.CalledProcessError as e:
        print(f"Error running yt-dlp: {e}")
        print(f"Output: {e.stdout}")
        print(f"Error: {e.stderr}")
        return None
    except Exception as e:
        print(f"Error: {str(e)}")
        return None
    finally:
        # Change back to the original directory
        os.chdir(original_dir)


def process_media_url(url, abs_url=None, library_name_or_id=DEFAULT_LIBRARY_NAME):
    """Process a single media URL - download audio and upload to Audiobookshelf.

    Args:
        url: URL to process
        abs_url: Audiobookshelf URL (optional)
        library_name_or_id: Library name or ID to upload to (optional, default: "Podcasts")

    Returns:
        True if successful, False otherwise
    """
    print(f"Processing media URL: {url}")

    # Create a temporary directory
    with tempfile.TemporaryDirectory(prefix="audiobookshelf-") as temp_dir:
        print(f"Created temporary directory: {temp_dir}")

        # Download audio
        mp3_file = download_audio(url, temp_dir)

        if not mp3_file:
            return False

        print(f"Audio extraction completed. File: {mp3_file}")

        # Check for API key
        api_key = os.environ.get("ABS_API_KEY")
        if not api_key:
            print("Error: Missing API key")
            print("Please set the ABS_API_KEY environment variable")
            return False

        # Initialize client
        if abs_url:
            client = AudiobookshelfClient(api_key, abs_url)
        else:
            client = AudiobookshelfClient(api_key)

        # Upload to Audiobookshelf
        print("Uploading to Audiobookshelf...")
        upload_response = client.upload_file(mp3_file, library_name_or_id)

        if upload_response:
            print("Upload successful!")
            return True
        else:
            print("Upload failed.")
            return False


def process_from_file(file_path, abs_url=None, library_name_or_id=DEFAULT_LIBRARY_NAME):
    """Process URLs from a file.

    Args:
        file_path: Path to file containing URLs
        abs_url: Audiobookshelf URL (optional)
        library_name_or_id: Library name or ID to upload to (optional, default: "Podcasts")

    Returns:
        Number of successfully processed URLs
    """
    if not os.path.isfile(file_path):
        print(f"Error: File not found: {file_path}")
        return 0

    success_count = 0

    # Read URLs from file
    with open(file_path, "r") as f:
        urls = f.readlines()

    # Process each URL
    for url in urls:
        url = url.strip()

        # Skip empty lines and comments
        if not url or url.startswith("#"):
            continue

        if process_media_url(url, abs_url, library_name_or_id):
            success_count += 1

            # Remove successfully processed URL from the file
            with open(file_path, "r") as f:
                lines = f.readlines()

            with open(file_path, "w") as f:
                for line in lines:
                    if line.strip() != url:
                        f.write(line)

            print(f"Removed successfully processed URL from {file_path}: {url}")
        else:
            print(f"Failed to process URL: {url}")

    return success_count


def upload_command(args, client):
    """Handle the upload command."""
    print(f"Uploading {args.file} to {client.base_url}...")

    # Extract title from filename if not provided
    title = args.title
    if not title:
        title = os.path.splitext(os.path.basename(args.file))[0]

    upload_response = client.upload_file(args.file, args.library, title)

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


def list_listened_command(args, client):
    """Handle the list-listened command."""
    print(f"Fetching listened episodes from {client.base_url}...")

    # Resolve library name to ID if needed
    library_id = args.library
    if not ("-" in library_id and len(library_id) > 30):
        # It's a library name, resolve it
        library_id, _ = client.get_library(args.library)
        if not library_id:
            print(f"Error: Library '{args.library}' not found.")
            return

    # Get library items first
    items_response = client.get_library_items(library_id)

    if not items_response or "results" not in items_response:
        print("No items found or unable to retrieve library items.")
        return

    listened_items = []

    for item in items_response["results"]:
        item_id = item["id"]

        # Try to get progress for this item
        progress_info = client.get_item_progress(item_id)

        # Check if item is finished (progress = 1.0 means 100% complete)
        if progress_info and progress_info.get("progress", 0) >= 1.0:
            listened_items.append(
                {
                    "id": item_id,
                    "title": item["media"]["metadata"]["title"],
                    "progress": progress_info.get("progress", 0),
                    "finished_at": progress_info.get("finishedAt"),
                    "duration": item["media"].get("duration", 0),
                }
            )

    if not listened_items:
        print("No listened episodes found.")
        return

    print(f"\nFound {len(listened_items)} listened episodes:")
    print("-" * 50)

    for item in listened_items:
        print(f"ID: {item['id']}")
        print(f"Title: {item['title']}")
        print(f"Progress: {item['progress']:.1%}")
        if item["finished_at"]:
            # Convert timestamp to readable date
            try:
                finished_date = datetime.fromtimestamp(item["finished_at"] / 1000)
                print(f"Finished: {finished_date.strftime('%Y-%m-%d %H:%M')}")
            except (ValueError, TypeError):
                print(f"Finished: {item['finished_at']}")
        if item["duration"]:
            duration_hours = item["duration"] / 3600
            print(f"Duration: {duration_hours:.1f} hours")
        print()


def cleanup_listened_command(args, client):
    """Handle the cleanup-listened command."""
    print(f"Finding listened episodes to clean up from {client.base_url}...")

    # Resolve library name to ID if needed
    library_id = args.library
    if not ("-" in library_id and len(library_id) > 30):
        # It's a library name, resolve it
        library_id, _ = client.get_library(args.library)
        if not library_id:
            print(f"Error: Library '{args.library}' not found.")
            return

    # Get library items
    items_response = client.get_library_items(library_id)

    if not items_response or "results" not in items_response:
        print("No items found or unable to retrieve library items.")
        return

    listened_items = []

    for item in items_response["results"]:
        item_id = item["id"]

        # Get progress for this item
        progress = client.get_item_progress(item_id)

        # Check if item is finished (progress = 1.0 means 100% complete)
        if progress and progress.get("progress", 0) >= 1.0:
            listened_items.append(
                {
                    "id": item_id,
                    "title": item["media"]["metadata"]["title"],
                    "progress": progress.get("progress", 0),
                }
            )

    if not listened_items:
        print("No listened episodes found to clean up.")
        return

    print(f"\nFound {len(listened_items)} listened episodes to remove:")
    print("-" * 50)

    for item in listened_items:
        print(f"- {item['title']} (ID: {item['id']})")

    if not args.force:
        response = input(
            f"\nAre you sure you want to remove {len(listened_items)} listened episodes? (y/N): "
        )
        if response.lower() not in ["y", "yes"]:
            print("Cleanup cancelled.")
            return

    # Remove the items
    removed_count = 0
    failed_count = 0

    for item in listened_items:
        print(f"Removing: {item['title']}")

        if client.remove_item(item["id"]):
            removed_count += 1
            print("  ✓ Removed successfully")
        else:
            failed_count += 1
            print("  ✗ Failed to remove")

    print("\nCleanup complete:")
    print(f"  Removed: {removed_count}")
    print(f"  Failed: {failed_count}")


def download_command(args):
    """Handle the download command."""
    if args.url:
        # Process a single URL
        if download_audio(args.url, args.output_dir):
            print("Download completed successfully.")
        else:
            print("Download failed.")
            return 1
    elif args.file_url_list:
        # Process URLs from a file
        if not os.path.isfile(args.file_url_list):
            print(f"Error: File not found: {args.file_url_list}")
            return 1

        success_count = 0
        total_count = 0

        # Read URLs from file
        with open(args.file_url_list, "r") as f:
            urls = f.readlines()

        # Process each URL
        for url in urls:
            url = url.strip()

            # Skip empty lines and comments
            if not url or url.startswith("#"):
                continue

            total_count += 1
            if download_audio(url, args.output_dir):
                success_count += 1

        print(f"Downloaded {success_count} of {total_count} URLs successfully.")
    else:
        print("Error: Either --url or --file-url-list must be specified.")
        return 1

    return 0


def process_command(args):
    """Handle the process command."""
    if args.url:
        # Process a single URL
        if process_media_url(args.url, args.abs_url, args.library):
            print("Processing completed successfully.")
        else:
            print("Processing failed.")
            return 1
    elif args.file_url_list:
        # Process URLs from a file
        success_count = process_from_file(
            args.file_url_list, args.abs_url, args.library
        )
        print(f"Processed {success_count} URLs successfully.")
    else:
        print("Error: Either --url or --file-url-list must be specified.")
        return 1

    return 0


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
        "--library",
        default=DEFAULT_LIBRARY_NAME,
        help=f'Library name or ID (default: "{DEFAULT_LIBRARY_NAME}")',
    )
    upload_parser.add_argument(
        "--title", help="Title for the media (defaults to filename)"
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

    # List listened command
    list_listened_parser = subparsers.add_parser(
        "list-listened", help="List episodes that have been completely listened to"
    )
    list_listened_parser.add_argument(
        "--url",
        default=os.environ.get("ABS_URL", DEFAULT_ABS_URL),
        help=f"Audiobookshelf URL (default: {DEFAULT_ABS_URL} or ABS_URL env var)",
    )
    list_listened_parser.add_argument(
        "--library",
        default=DEFAULT_LIBRARY_NAME,
        help=f'Library name or ID (default: "{DEFAULT_LIBRARY_NAME}")',
    )

    # Cleanup listened command
    cleanup_listened_parser = subparsers.add_parser(
        "cleanup-listened", help="Remove episodes that have been completely listened to"
    )
    cleanup_listened_parser.add_argument(
        "--url",
        default=os.environ.get("ABS_URL", DEFAULT_ABS_URL),
        help=f"Audiobookshelf URL (default: {DEFAULT_ABS_URL} or ABS_URL env var)",
    )
    cleanup_listened_parser.add_argument(
        "--library",
        default=DEFAULT_LIBRARY_NAME,
        help=f'Library name or ID (default: "{DEFAULT_LIBRARY_NAME}")',
    )
    cleanup_listened_parser.add_argument(
        "--force", action="store_true", help="Skip confirmation prompt"
    )

    # Download command
    download_parser = subparsers.add_parser(
        "download", help="Download audio from a URL or list of URLs"
    )
    download_parser.add_argument("--url", help="URL to download from")
    download_parser.add_argument(
        "--file-url-list", help="File containing URLs to download (one per line)"
    )
    download_parser.add_argument(
        "--output-dir", default=os.getcwd(), help="Directory to save downloaded files"
    )

    # Process command (download + upload)
    process_parser = subparsers.add_parser(
        "process",
        help="Download audio from a URL or list of URLs and upload to Audiobookshelf",
    )
    process_parser.add_argument("--url", help="URL to process")
    process_parser.add_argument(
        "--file-url-list", help="File containing URLs to process (one per line)"
    )
    process_parser.add_argument(
        "--abs-url",
        default=os.environ.get("ABS_URL", DEFAULT_ABS_URL),
        help=f"Audiobookshelf URL (default: {DEFAULT_ABS_URL} or ABS_URL env var)",
    )
    process_parser.add_argument(
        "--library",
        default=DEFAULT_LIBRARY_NAME,
        help=f'Library name or ID (default: "{DEFAULT_LIBRARY_NAME}")',
    )

    # Handle case where no arguments are provided
    if len(sys.argv) == 1:
        parser.print_help()
        return 1

    # Make sure the first argument is a valid command
    valid_commands = [
        "upload",
        "libraries",
        "list-listened",
        "cleanup-listened",
        "download",
        "process",
        "-h",
        "--help",
    ]
    if sys.argv[1] not in valid_commands:
        print(f"Error: '{sys.argv[1]}' is not a recognized command.")
        print("Commands must come first, before any options.")
        print(
            "\nAvailable commands: upload, libraries, list-listened, cleanup-listened, download, process"
        )
        print("\nUsage examples:")
        print(
            "  audiobookshelf upload --url https://example.com --file file.mp3 --library-id ID"
        )
        print("  audiobookshelf libraries --url https://example.com")
        print(
            "  audiobookshelf list-listened --url https://example.com --library-id ID"
        )
        print(
            "  audiobookshelf cleanup-listened --url https://example.com --library-id ID"
        )
        print("  audiobookshelf download --url https://youtube.com/watch?v=example")
        print("  audiobookshelf process --file-url-list /path/to/urls.txt")
        return 1

    args = parser.parse_args()

    # Handle commands that don't require API key
    if args.command == "download":
        return download_command(args)

    # Check for API key for commands that need it
    api_key = os.environ.get("ABS_API_KEY")
    if not api_key:
        print("Error: Missing API key")
        print("Please set the ABS_API_KEY environment variable")
        return 1

    # Handle commands that require API key
    if args.command == "process":
        return process_command(args)
    else:
        # Initialize client with URL from command arguments
        client = AudiobookshelfClient(api_key, args.url)

        # Handle other commands
        if args.command == "upload":
            upload_command(args, client)
        elif args.command == "libraries":
            libraries_command(client)
        elif args.command == "list-listened":
            list_listened_command(args, client)
        elif args.command == "cleanup-listened":
            cleanup_listened_command(args, client)
        else:
            parser.print_help()

    return 0


if __name__ == "__main__":
    sys.exit(main())
