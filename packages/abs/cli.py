"""CLI argument parsing and dispatch for the Audiobookshelf CLI."""

import os
import sys

import click

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


def _default_abs_url():
    return _read_secret("ABS_URL") or DEFAULT_ABS_URL


@click.group()
def cli():
    """Interact with Audiobookshelf from the command line."""


@cli.command()
@click.option(
    "--url",
    default=lambda: _default_abs_url(),
    show_default=True,
    help=f"Audiobookshelf URL (default: sops secret or {DEFAULT_ABS_URL})",
)
@click.option("--file", "file_path", required=True, help="Audio file to upload")
@click.option(
    "--library",
    default=DEFAULT_LIBRARY_NAME,
    show_default=True,
    help=f'Library name or ID (default: "{DEFAULT_LIBRARY_NAME}")',
)
@click.option(
    "--title", default=None, help="Title for the media (defaults to filename)"
)
def upload(url, file_path, library, title):
    """Upload an audio file to Audiobookshelf."""
    api_key = os.environ.get("ABS_API_KEY")
    if not api_key:
        click.echo("Error: Missing API key")
        click.echo("Please set the ABS_API_KEY environment variable")
        sys.exit(1)
    client = AudiobookshelfClient(api_key, url)
    upload_command(file_path, library, title, client)


@cli.command()
@click.option(
    "--url",
    default=lambda: _default_abs_url(),
    show_default=True,
    help=f"Audiobookshelf URL (default: sops secret or {DEFAULT_ABS_URL})",
)
def libraries(url):
    """List available libraries in Audiobookshelf."""
    api_key = os.environ.get("ABS_API_KEY")
    if not api_key:
        click.echo("Error: Missing API key")
        click.echo("Please set the ABS_API_KEY environment variable")
        sys.exit(1)
    client = AudiobookshelfClient(api_key, url)
    libraries_command(client)


@cli.command("list-listened")
@click.option(
    "--url",
    default=lambda: _default_abs_url(),
    show_default=True,
    help=f"Audiobookshelf URL (default: sops secret or {DEFAULT_ABS_URL})",
)
@click.option(
    "--library",
    default=DEFAULT_LIBRARY_NAME,
    show_default=True,
    help=f'Library name or ID (default: "{DEFAULT_LIBRARY_NAME}")',
)
def list_listened(url, library):
    """List episodes that have been completely listened to."""
    api_key = os.environ.get("ABS_API_KEY")
    if not api_key:
        click.echo("Error: Missing API key")
        click.echo("Please set the ABS_API_KEY environment variable")
        sys.exit(1)
    client = AudiobookshelfClient(api_key, url)
    list_listened_command(library, client)


@cli.command("cleanup-listened")
@click.option(
    "--url",
    default=lambda: _default_abs_url(),
    show_default=True,
    help=f"Audiobookshelf URL (default: sops secret or {DEFAULT_ABS_URL})",
)
@click.option(
    "--library",
    default=DEFAULT_LIBRARY_NAME,
    show_default=True,
    help=f'Library name or ID (default: "{DEFAULT_LIBRARY_NAME}")',
)
@click.option("--force", is_flag=True, help="Skip confirmation prompt")
def cleanup_listened(url, library, force):
    """Remove episodes that have been completely listened to."""
    api_key = os.environ.get("ABS_API_KEY")
    if not api_key:
        click.echo("Error: Missing API key")
        click.echo("Please set the ABS_API_KEY environment variable")
        sys.exit(1)
    client = AudiobookshelfClient(api_key, url)
    cleanup_listened_command(library, force, client)


@cli.command()
@click.option("--url", default=None, help="URL to download from")
@click.option(
    "--file-url-list",
    default=None,
    help="File containing URLs to download (one per line)",
)
@click.option(
    "--output-dir",
    default=lambda: os.getcwd(),
    show_default=True,
    help="Directory to save downloaded files",
)
def download(url, file_url_list, output_dir):
    """Download audio from a URL or list of URLs."""
    result = download_command(url, file_url_list, output_dir)
    if result != 0:
        sys.exit(result)


@cli.command()
@click.option("--url", default=None, help="URL to process")
@click.option(
    "--file-url-list",
    default=None,
    help="File containing URLs to process (one per line)",
)
@click.option(
    "--abs-url",
    default=lambda: _default_abs_url(),
    show_default=True,
    help=f"Audiobookshelf URL (default: sops secret or {DEFAULT_ABS_URL})",
)
@click.option(
    "--library",
    default=DEFAULT_LIBRARY_NAME,
    show_default=True,
    help=f'Library name or ID (default: "{DEFAULT_LIBRARY_NAME}")',
)
def process(url, file_url_list, abs_url, library):
    """Download audio from a URL or list of URLs and upload to Audiobookshelf."""
    api_key = os.environ.get("ABS_API_KEY")
    if not api_key:
        click.echo("Error: Missing API key")
        click.echo("Please set the ABS_API_KEY environment variable")
        sys.exit(1)
    result = process_command(url, file_url_list, abs_url, library)
    if result != 0:
        sys.exit(result)


def main():
    """Main entry point for the script."""
    cli(prog_name="abs")
