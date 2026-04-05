"""Command handlers for the Audiobookshelf CLI."""

import os
from datetime import datetime

from download import download_audio
from process import process_media_url, process_from_file


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
            print("  Removed successfully")
        else:
            failed_count += 1
            print("  Failed to remove")

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
