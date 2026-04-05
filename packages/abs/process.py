"""Media processing: download + upload pipeline."""

import os
import tempfile

from client import AudiobookshelfClient, _read_secret, DEFAULT_LIBRARY_NAME
from download import download_audio


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
        api_key = _read_secret("ABS_API_KEY")
        if not api_key:
            print("Error: Missing API key")
            print("Please ensure sops-nix secret audiobookshelf-api-token exists")
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
