"""CLI argument parsing and dispatch for the Audiobookshelf CLI."""

import argparse
import os
import sys

from client import (
    AudiobookshelfClient,
    _read_secret,
    DEFAULT_ABS_URL,
    DEFAULT_LIBRARY_NAME,
)
from commands import (
    upload_command,
    libraries_command,
    list_listened_command,
    cleanup_listened_command,
    download_command,
    process_command,
)


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        prog="abs",
        description="Interact with Audiobookshelf from the command line.",
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
        default=_read_secret("ABS_URL") or DEFAULT_ABS_URL,
        help=f"Audiobookshelf URL (default: sops secret or {DEFAULT_ABS_URL})",
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
        default=_read_secret("ABS_URL") or DEFAULT_ABS_URL,
        help=f"Audiobookshelf URL (default: sops secret or {DEFAULT_ABS_URL})",
    )

    # List listened command
    list_listened_parser = subparsers.add_parser(
        "list-listened", help="List episodes that have been completely listened to"
    )
    list_listened_parser.add_argument(
        "--url",
        default=_read_secret("ABS_URL") or DEFAULT_ABS_URL,
        help=f"Audiobookshelf URL (default: sops secret or {DEFAULT_ABS_URL})",
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
        default=_read_secret("ABS_URL") or DEFAULT_ABS_URL,
        help=f"Audiobookshelf URL (default: sops secret or {DEFAULT_ABS_URL})",
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
        default=_read_secret("ABS_URL") or DEFAULT_ABS_URL,
        help=f"Audiobookshelf URL (default: sops secret or {DEFAULT_ABS_URL})",
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
        print("  abs upload --url https://example.com --file file.mp3 --library-id ID")
        print("  abs libraries --url https://example.com")
        print("  abs list-listened --url https://example.com --library-id ID")
        print("  abs cleanup-listened --url https://example.com --library-id ID")
        print("  abs download --url https://youtube.com/watch?v=example")
        print("  abs process --file-url-list /path/to/urls.txt")
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
