"""Click CLI group and subcommands for giffer."""

import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

import click

from constants import (
    DEFAULT_MAX_HEIGHT,
    DEFAULT_SEGMENT_DURATION,
    DEFAULT_URL_FILE,
    SITE_CONFIGS,
)
from download import batch_download_impl, download_single_video
from scrape import get_playlist_urls, scrape_and_download_impl
from split import download_with_split, split_path
from utils import (
    DURATION,
    get_default_ytdlp_args,
    run_gallery_dl,
    run_yt_dlp,
)


class GifferGroup(click.Group):
    """Custom group that passes unknown commands to yt-dlp/gallery-dl."""

    def parse_args(self, ctx, args):
        # Check if first non-option arg is a subcommand
        subcommands = set(self.commands.keys())
        first_positional = None
        for arg in args:
            if not arg.startswith("-"):
                first_positional = arg
                break

        if first_positional and first_positional not in subcommands:
            # Not a subcommand, store args for passthrough
            ctx.ensure_object(dict)
            ctx.obj["passthrough_args"] = args
            ctx.obj["passthrough_mode"] = True
            return []

        return super().parse_args(ctx, args)

    def invoke(self, ctx):
        ctx.ensure_object(dict)
        if ctx.obj.get("passthrough_mode"):
            # Handle passthrough mode
            args = ctx.obj["passthrough_args"]

            # Parse our flags manually
            gallery = False
            ytdlp = False
            remaining = []
            i = 0
            while i < len(args):
                if args[i] == "--gallery":
                    gallery = True
                elif args[i] == "--yt-dlp":
                    ytdlp = True
                elif args[i] in ("-h", "--help") and not remaining:
                    return super().invoke(ctx)
                else:
                    remaining.append(args[i])
                i += 1

            if not remaining:
                click.echo(ctx.get_help())
                return

            if gallery and ytdlp:
                click.echo("Error: Cannot use both --gallery and --yt-dlp", err=True)
                ctx.exit(1)

            if gallery:
                result = run_gallery_dl(remaining)
            elif ytdlp:
                # Prepend defaults, user args can override
                result = run_yt_dlp(get_default_ytdlp_args() + remaining)
            else:
                # Prepend defaults, user args can override
                result = run_yt_dlp(get_default_ytdlp_args() + remaining)
                if result.returncode != 0:
                    click.echo(
                        "\nyt-dlp failed, trying gallery-dl as fallback...\n", err=True
                    )
                    result = run_gallery_dl(remaining)

            ctx.exit(result.returncode)
        else:
            return super().invoke(ctx)


@click.group(cls=GifferGroup, invoke_without_command=True)
@click.option("--gallery", is_flag=True, help="Force using gallery-dl")
@click.option("--yt-dlp", "ytdlp", is_flag=True, help="Force using yt-dlp")
@click.pass_context
def cli(ctx, gallery, ytdlp):
    """Wrapper for yt-dlp and gallery-dl with optional video splitting.

    By default, passes all arguments to yt-dlp.
    If yt-dlp fails, automatically tries gallery-dl as fallback.
    Use --gallery or --yt-dlp to force a specific tool (disables fallback).

    \b
    Default usage (passthrough):
      giffer "https://youtube.com/watch?v=xxx"
      giffer "https://youtube.com/watch?v=xxx" -f best
      giffer --gallery "https://example.com"
      giffer --yt-dlp "https://reddit.com/..."

    \b
    Duration formats: 30 (seconds), 30s, 2m, 1m30s, 1h, 1h30m, 1h2m3s
    """
    ctx.ensure_object(dict)
    if ctx.invoked_subcommand is None and not ctx.obj.get("passthrough_mode"):
        click.echo(ctx.get_help())


@cli.command()
@click.argument("url")
@click.option("-o", "--output-dir", help="Output directory")
@click.option(
    "-d",
    "--duration",
    type=DURATION,
    default=DEFAULT_SEGMENT_DURATION,
    help=f"Segment duration (default: {DEFAULT_SEGMENT_DURATION}s)",
)
@click.option(
    "--skip-start", type=DURATION, default=0, help="Skip from start (default: 0)"
)
@click.option("--skip-end", type=DURATION, default=0, help="Skip from end (default: 0)")
def split(url, output_dir, duration, skip_start, skip_end):
    """Download video and split into segments."""
    success = download_with_split(url, duration, skip_start, skip_end, output_dir)
    sys.exit(0 if success else 1)


@cli.command()
@click.argument("url")
@click.option("-o", "--output-dir", help="Output directory")
@click.option(
    "-w",
    "--workers",
    type=int,
    default=1,
    help="Parallel workers for playlists (default: 1)",
)
@click.option("--split", "do_split", is_flag=True, help="Split videos after download")
@click.option(
    "-d",
    "--duration",
    type=DURATION,
    default=DEFAULT_SEGMENT_DURATION,
    help=f"Segment duration if splitting (default: {DEFAULT_SEGMENT_DURATION}s)",
)
@click.option(
    "--skip-start",
    type=DURATION,
    default=0,
    help="Skip from start if splitting (default: 0)",
)
@click.option(
    "--skip-end",
    type=DURATION,
    default=0,
    help="Skip from end if splitting (default: 0)",
)
@click.option(
    "--max-height",
    type=int,
    default=DEFAULT_MAX_HEIGHT,
    help=f"Maximum video height (default: {DEFAULT_MAX_HEIGHT})",
)
@click.option(
    "--gallery",
    is_flag=True,
    help="Use gallery-dl as primary downloader (fall back to yt-dlp)",
)
def download(
    url,
    output_dir,
    workers,
    do_split,
    duration,
    skip_start,
    skip_end,
    max_height,
    gallery,
):
    """Download video(s) from URL or playlist.

    For playlist URLs, use -w/--workers to download videos in parallel.
    Use --split to split videos into segments after download.
    Use --gallery to prefer gallery-dl over yt-dlp.
    """
    split = do_split

    if gallery:
        gallery_args = []
        if output_dir:
            gallery_args.extend(["-d", output_dir])
        gallery_args.append(url)
        click.echo("Downloading with gallery-dl...")
        result = run_gallery_dl(gallery_args)
        sys.exit(result.returncode)

    if workers > 1:
        click.echo("Extracting video URLs from playlist...")
        urls = get_playlist_urls(url)

        if not urls:
            click.echo("No videos found or not a playlist, downloading as single video")
            if split:
                success = download_with_split(
                    url, duration, skip_start, skip_end, output_dir
                )
                sys.exit(0 if success else 1)
            else:
                args = [url]
                if output_dir:
                    args.extend(["-o", f"{output_dir}/%(title)s.%(ext)s"])
                result = run_yt_dlp(args)
                sys.exit(result.returncode)

        click.echo(f"Found {len(urls)} videos, downloading with {workers} workers")
        click.echo(f"Split: {'enabled' if split else 'disabled'}\n")

        success_count = 0
        failed_urls = []

        with ThreadPoolExecutor(max_workers=workers) as executor:
            futures = {
                executor.submit(
                    download_single_video,
                    video_url,
                    output_dir,
                    max_height,
                    split,
                    duration,
                    skip_start,
                    skip_end,
                ): video_url
                for video_url in urls
            }

            for future in as_completed(futures):
                video_url, success = future.result()
                if success:
                    success_count += 1
                    click.echo(f"[{success_count}/{len(urls)}] Completed: {video_url}")
                else:
                    failed_urls.append(video_url)
                    click.echo(f"[FAILED] {video_url}")

        click.echo(f"\n=== Done: {success_count}/{len(urls)} successful ===")
        sys.exit(0 if not failed_urls else 1)
    else:
        if split:
            success = download_with_split(
                url, duration, skip_start, skip_end, output_dir
            )
            sys.exit(0 if success else 1)
        else:
            args = [url]
            if output_dir:
                args.extend(["-o", f"{output_dir}/%(title)s.%(ext)s"])
            result = run_yt_dlp(args)
            sys.exit(result.returncode)


@cli.command()
@click.argument("path")
@click.option("-o", "--output-dir", help="Output directory")
@click.option("--cleanup", is_flag=True, help="Remove source files after splitting")
@click.option(
    "-r/-R", "--recursive/--no-recursive", default=True, help="Process subdirectories"
)
@click.option("-e", "--extensions", multiple=True, help="File extensions to process")
@click.option(
    "-d",
    "--duration",
    type=DURATION,
    default=DEFAULT_SEGMENT_DURATION,
    help=f"Segment duration (default: {DEFAULT_SEGMENT_DURATION}s)",
)
@click.option(
    "--skip-start", type=DURATION, default=0, help="Skip from start (default: 0)"
)
@click.option("--skip-end", type=DURATION, default=0, help="Skip from end (default: 0)")
def process(
    path, output_dir, cleanup, recursive, extensions, duration, skip_start, skip_end
):
    """Split local video file(s)."""
    exts = None
    if extensions:
        exts = [f".{e.lstrip('.')}" for e in extensions]
    success = split_path(
        path, duration, skip_start, skip_end, output_dir, cleanup, recursive, exts
    )
    sys.exit(0 if success else 1)


@cli.command()
@click.option(
    "-f",
    "--file",
    "url_file",
    default=DEFAULT_URL_FILE,
    help=f"URL list file (default: {DEFAULT_URL_FILE})",
)
@click.option("-o", "--output-dir", help="Output directory")
@click.option(
    "-w", "--workers", type=int, default=1, help="Parallel workers (default: 1)"
)
@click.option("--embed-subs/--no-embed-subs", default=True, help="Embed subtitles")
@click.option(
    "--max-height",
    type=int,
    default=DEFAULT_MAX_HEIGHT,
    help=f"Maximum video height (default: {DEFAULT_MAX_HEIGHT})",
)
@click.option(
    "--clean-list",
    is_flag=True,
    help="Remove successfully downloaded URLs from the list file",
)
@click.option(
    "--gallery",
    is_flag=True,
    help="Force gallery-dl for all URLs (skip yt-dlp)",
)
@click.option(
    "--ytdlp",
    is_flag=True,
    help="Force yt-dlp for all URLs (skip gallery-dl fallback)",
)
def batch(
    url_file, output_dir, workers, embed_subs, max_height, clean_list, gallery, ytdlp
):
    """Download videos from a URL list file."""
    if gallery and ytdlp:
        raise click.UsageError("Cannot use both --gallery and --ytdlp")
    success = batch_download_impl(
        url_file,
        output_dir,
        embed_subs,
        max_height,
        workers,
        clean_list,
        gallery,
        ytdlp,
    )
    sys.exit(0 if success else 1)


@cli.command()
@click.argument("url")
@click.option("-o", "--output-dir", help="Output directory")
@click.option("--start-page", type=int, default=1, help="Starting page (default: 1)")
@click.option("--end-page", type=int, help="Ending page")
@click.option(
    "-s",
    "--site",
    type=click.Choice(list(SITE_CONFIGS.keys())),
    help="Use preset config for site",
)
@click.option(
    "-p", "--pattern", help="Custom regex pattern for URLs (overrides --site)"
)
@click.option(
    "-f",
    "--filter",
    "url_filter",
    help="Regex to filter by video title (case-insensitive, include matching)",
)
@click.option(
    "-x",
    "--exclude",
    "url_exclude",
    help="Regex to filter by video title (case-insensitive, exclude matching)",
)
@click.option(
    "-w", "--workers", type=int, default=4, help="Parallel workers (default: 4)"
)
@click.option(
    "--max-height",
    type=int,
    default=DEFAULT_MAX_HEIGHT,
    help=f"Maximum video height (default: {DEFAULT_MAX_HEIGHT})",
)
@click.option("--split", "do_split", is_flag=True, help="Split videos after download")
@click.option(
    "--split-pages/--no-split-pages",
    default=True,
    help="Organize files into page-N directories (default: enabled)",
)
@click.option(
    "-d",
    "--duration",
    type=DURATION,
    default=DEFAULT_SEGMENT_DURATION,
    help=f"Segment duration (default: {DEFAULT_SEGMENT_DURATION}s)",
)
@click.option(
    "--skip-start", type=DURATION, default=0, help="Skip from start (default: 0)"
)
@click.option("--skip-end", type=DURATION, default=0, help="Skip from end (default: 0)")
@click.option(
    "--search-dir",
    "search_dirs",
    multiple=True,
    help="Search directory for existing files to skip (recursive, repeatable)",
)
def scrape(
    url,
    output_dir,
    start_page,
    end_page,
    site,
    pattern,
    url_filter,
    url_exclude,
    workers,
    max_height,
    do_split,
    split_pages,
    duration,
    skip_start,
    skip_end,
    search_dirs,
):
    """Scrape paginated pages and download videos.

    Use --site to select a preset config, or --pattern for custom regex.
    Use --filter to include only videos with titles matching a pattern (e.g., -f "pink").
    Use --exclude to skip videos with titles matching a pattern.
    Use --split-pages to organize downloads into page-N directories. Re-running
    with --split-pages will move existing files to their correct page directories.
    Use --search-dir to skip downloading files that already exist in another directory.
    """
    pagination = None
    if site:
        config = SITE_CONFIGS.get(site, {})
        if pattern is None:
            pattern = config.get("pattern")
        pagination = config.get("pagination")
    success = scrape_and_download_impl(
        url,
        start_page,
        end_page,
        pattern,
        pagination,
        workers,
        output_dir,
        max_height,
        do_split,
        duration,
        skip_start,
        skip_end,
        url_filter=url_filter,
        url_exclude=url_exclude,
        split_pages=split_pages,
        search_dirs=search_dirs if search_dirs else None,
    )
    sys.exit(0 if success else 1)
