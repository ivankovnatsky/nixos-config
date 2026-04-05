"""Command handlers for the Audiobookshelf CLI."""

import os
from datetime import datetime

import click

from download import download_audio
from process import process_media_url, process_from_file


def upload_command(file_path, library, title, client):
    """Handle the upload command."""
    click.echo(f"Uploading {file_path} to {client.base_url}...")

    # Extract title from filename if not provided
    if not title:
        title = os.path.splitext(os.path.basename(file_path))[0]

    upload_response = client.upload_file(file_path, library, title)

    if upload_response:
        click.echo("Upload successful!")
        click.echo(f"Response: {upload_response}")
    else:
        click.echo("Upload failed. Please check your connection and API key.")


def libraries_command(client):
    """Handle the libraries command."""
    click.echo(f"Fetching libraries from {client.base_url}...")

    libraries = client.get_libraries()

    if not libraries or "libraries" not in libraries:
        click.echo("No libraries found or unable to retrieve libraries.")
        return

    click.echo("\nAvailable Libraries:")
    click.echo("-----------------")

    for library in libraries["libraries"]:
        click.echo(f"ID: {library['id']}")
        click.echo(f"Name: {library['name']}")
        click.echo(f"Media Type: {library.get('mediaType', 'Unknown')}")

        # Display folders if available
        if "folders" in library and library["folders"]:
            click.echo("Folders:")
            for folder in library["folders"]:
                click.echo(f"  - ID: {folder['id']}")
                if "fullPath" in folder:
                    click.echo(f"    Path: {folder['fullPath']}")

        click.echo("")


def list_listened_command(library, client):
    """Handle the list-listened command."""
    click.echo(f"Fetching listened episodes from {client.base_url}...")

    # Resolve library name to ID if needed
    library_id = library
    if not ("-" in library_id and len(library_id) > 30):
        # It's a library name, resolve it
        library_id, _ = client.get_library(library)
        if not library_id:
            click.echo(f"Error: Library '{library}' not found.")
            return

    # Get library items first
    items_response = client.get_library_items(library_id)

    if not items_response or "results" not in items_response:
        click.echo("No items found or unable to retrieve library items.")
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
        click.echo("No listened episodes found.")
        return

    click.echo(f"\nFound {len(listened_items)} listened episodes:")
    click.echo("-" * 50)

    for item in listened_items:
        click.echo(f"ID: {item['id']}")
        click.echo(f"Title: {item['title']}")
        click.echo(f"Progress: {item['progress']:.1%}")
        if item["finished_at"]:
            # Convert timestamp to readable date
            try:
                finished_date = datetime.fromtimestamp(item["finished_at"] / 1000)
                click.echo(f"Finished: {finished_date.strftime('%Y-%m-%d %H:%M')}")
            except (ValueError, TypeError):
                click.echo(f"Finished: {item['finished_at']}")
        if item["duration"]:
            duration_hours = item["duration"] / 3600
            click.echo(f"Duration: {duration_hours:.1f} hours")
        click.echo("")


def cleanup_listened_command(library, force, client):
    """Handle the cleanup-listened command."""
    click.echo(f"Finding listened episodes to clean up from {client.base_url}...")

    # Resolve library name to ID if needed
    library_id = library
    if not ("-" in library_id and len(library_id) > 30):
        # It's a library name, resolve it
        library_id, _ = client.get_library(library)
        if not library_id:
            click.echo(f"Error: Library '{library}' not found.")
            return

    # Get library items
    items_response = client.get_library_items(library_id)

    if not items_response or "results" not in items_response:
        click.echo("No items found or unable to retrieve library items.")
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
        click.echo("No listened episodes found to clean up.")
        return

    click.echo(f"\nFound {len(listened_items)} listened episodes to remove:")
    click.echo("-" * 50)

    for item in listened_items:
        click.echo(f"- {item['title']} (ID: {item['id']})")

    if not force:
        response = click.prompt(
            f"\nAre you sure you want to remove {len(listened_items)} listened episodes? (y/N)",
            default="N",
        )
        if response.lower() not in ["y", "yes"]:
            click.echo("Cleanup cancelled.")
            return

    # Remove the items
    removed_count = 0
    failed_count = 0

    for item in listened_items:
        click.echo(f"Removing: {item['title']}")

        if client.remove_item(item["id"]):
            removed_count += 1
            click.echo("  Removed successfully")
        else:
            failed_count += 1
            click.echo("  Failed to remove")

    click.echo("\nCleanup complete:")
    click.echo(f"  Removed: {removed_count}")
    click.echo(f"  Failed: {failed_count}")


def download_command(url, file_url_list, output_dir):
    """Handle the download command."""
    if url:
        # Process a single URL
        if download_audio(url, output_dir):
            click.echo("Download completed successfully.")
        else:
            click.echo("Download failed.")
            return 1
    elif file_url_list:
        # Process URLs from a file
        if not os.path.isfile(file_url_list):
            click.echo(f"Error: File not found: {file_url_list}")
            return 1

        success_count = 0
        total_count = 0

        # Read URLs from file
        with open(file_url_list, "r") as f:
            urls = f.readlines()

        # Process each URL
        for u in urls:
            u = u.strip()

            # Skip empty lines and comments
            if not u or u.startswith("#"):
                continue

            total_count += 1
            if download_audio(u, output_dir):
                success_count += 1

        click.echo(f"Downloaded {success_count} of {total_count} URLs successfully.")
    else:
        click.echo("Error: Either --url or --file-url-list must be specified.")
        return 1

    return 0


def process_command(url, file_url_list, abs_url, library):
    """Handle the process command."""
    if url:
        # Process a single URL
        if process_media_url(url, abs_url, library):
            click.echo("Processing completed successfully.")
        else:
            click.echo("Processing failed.")
            return 1
    elif file_url_list:
        # Process URLs from a file
        success_count = process_from_file(file_url_list, abs_url, library)
        click.echo(f"Processed {success_count} URLs successfully.")
    else:
        click.echo("Error: Either --url or --file-url-list must be specified.")
        return 1

    return 0
