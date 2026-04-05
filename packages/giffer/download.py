"""Batch and single-video download functions."""

from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import click

from constants import (
    DEFAULT_FAILED_FILE,
    DEFAULT_MAX_HEIGHT,
    DEFAULT_SUB_LANGS,
    DEFAULT_URL_FILE,
)
from split import split_single_video
from utils import (
    fix_unknown_extensions,
    get_format_string,
    get_output_dir,
    run_gallery_dl,
    run_yt_dlp,
)


def append_failed_url(url, failed_file=DEFAULT_FAILED_FILE):
    """Append a failed URL to the failed list file."""
    try:
        with open(failed_file, "a") as f:
            f.write(url + "\n")
    except Exception as e:
        click.echo(f"Warning: Could not write to {failed_file}: {e}", err=True)


def remove_url_from_file(url_to_remove, url_file):
    """Remove a specific URL from the file immediately"""
    try:
        with open(url_file, "r") as f:
            lines = f.readlines()

        with open(url_file, "w") as f:
            for line in lines:
                if line.strip() != url_to_remove:
                    f.write(line)
    except Exception as e:
        click.echo(f"Warning: Could not remove URL from file: {e}", err=True)


def download_single_video(
    url,
    output_dir,
    max_height=DEFAULT_MAX_HEIGHT,
    split=False,
    segment_duration=10,
    skip_start=0,
    skip_end=0,
):
    """Download a single video and optionally split it, returns (url, success)"""
    out_dir = get_output_dir(output_dir)
    output_template = str(out_dir / "%(title)s.%(ext)s")

    cmd_args = [
        "-f",
        get_format_string(max_height),
        "-o",
        output_template,
        "--print",
        "after_move:filepath",
        url,
    ]

    result = run_yt_dlp(cmd_args, capture_output=True)
    downloaded_file = None

    if result.returncode == 0:
        downloaded_file = result.stdout.strip().split("\n")[-1]
        if downloaded_file and not Path(downloaded_file).exists():
            downloaded_file = None

    # Fallback to gallery-dl if yt-dlp failed
    if downloaded_file is None:
        gallery_args = ["-d", str(out_dir), url]
        gallery_result = run_gallery_dl(gallery_args)
        if gallery_result.returncode == 0:
            return (url, True)
        return (url, False)

    if not split:
        return (url, True)

    if downloaded_file and Path(downloaded_file).exists():
        success = split_single_video(
            downloaded_file,
            segment_duration,
            skip_start,
            skip_end,
            output_dir,
            cleanup=True,
        )
        return (url, success)

    return (url, False)


def batch_download_single(
    url,
    output_dir,
    embed_subs=True,
    max_height=DEFAULT_MAX_HEIGHT,
    force_gallery=False,
    force_ytdlp=False,
):
    """Download a single URL with yt-dlp, falling back to gallery-dl. Returns (url, success)."""
    out_dir = get_output_dir(output_dir)
    existing_files = set(out_dir.glob("*.unknown_video"))
    output_template = str(out_dir / "%(title)s.%(ext)s")

    if force_gallery:
        gallery_args = ["-d", str(out_dir), url]
        gallery_result = run_gallery_dl(gallery_args)
        return (url, gallery_result.returncode == 0)

    cmd_args = []
    if embed_subs:
        cmd_args.extend(
            ["--write-auto-subs", "--embed-subs", "--sub-langs", DEFAULT_SUB_LANGS]
        )

    cmd_args.extend(
        [
            "--check-formats",
            "-f",
            get_format_string(max_height),
            "-o",
            output_template,
            url,
        ]
    )

    result = run_yt_dlp(cmd_args)
    if result.returncode == 0:
        fix_unknown_extensions(out_dir, existing_files)
        return (url, True)

    if force_ytdlp:
        return (url, False)

    gallery_args = ["-d", str(out_dir), url]
    gallery_result = run_gallery_dl(gallery_args)
    return (url, gallery_result.returncode == 0)


def batch_download_impl(
    url_file=None,
    output_dir=None,
    embed_subs=True,
    max_height=DEFAULT_MAX_HEIGHT,
    workers=1,
    clean_list=False,
    force_gallery=False,
    force_ytdlp=False,
):
    """Download videos from a list file"""
    if url_file is None:
        url_file = DEFAULT_URL_FILE

    url_path = Path(url_file)
    if not url_path.exists():
        click.echo(f"No URLs to process: {url_file} not found")
        return True

    with open(url_path, "r") as f:
        urls = [
            line.strip()
            for line in f
            if line.strip() and not line.strip().startswith("#")
        ]

    if not urls:
        click.echo("No URLs to process")
        return True

    total_count = len(urls)
    click.echo(f"Processing {total_count} URLs with {workers} worker(s)")

    if workers > 1:
        success_count = 0
        failed_urls = []

        with ThreadPoolExecutor(max_workers=workers) as executor:
            futures = {
                executor.submit(
                    batch_download_single,
                    url,
                    output_dir,
                    embed_subs,
                    max_height,
                    force_gallery,
                    force_ytdlp,
                ): url
                for url in urls
            }

            for future in as_completed(futures):
                url, success = future.result()
                if success:
                    success_count += 1
                    if clean_list:
                        remove_url_from_file(url, url_file)
                    click.echo(f"[{success_count}/{total_count}] Completed: {url}")
                else:
                    failed_urls.append(url)
                    append_failed_url(url)
                    click.echo(f"[FAILED] {url}")

        click.echo(
            f"Processing complete. {success_count}/{total_count} URLs downloaded successfully"
        )
        return len(failed_urls) == 0
    else:
        success_count = 0
        for url in urls:
            click.echo(f"Downloading: {url}")
            _, success = batch_download_single(
                url, output_dir, embed_subs, max_height, force_gallery, force_ytdlp
            )
            if success:
                click.echo(f"Successfully downloaded: {url}")
                if clean_list:
                    remove_url_from_file(url, url_file)
                success_count += 1
            else:
                click.echo(f"Failed to download: {url}")
                append_failed_url(url)

        if total_count > 0:
            click.echo(
                f"Processing complete. {success_count}/{total_count} URLs downloaded successfully"
            )

        return success_count == total_count
