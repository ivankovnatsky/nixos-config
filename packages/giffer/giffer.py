#!/usr/bin/env python3
"""
giffer - A wrapper for yt-dlp and gallery-dl with optional video splitting.

By default, this tool passes all arguments directly to yt-dlp or gallery-dl.
Use subcommands for additional functionality like splitting.
"""

import json
import re
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import click

DEFAULT_URL_FILE = ".list.txt"
DEFAULT_MAX_HEIGHT = 1080
DEFAULT_SUB_LANGS = "en"
DEFAULT_SEGMENT_DURATION = 10

SITE_CONFIGS = {
    "3": {
        "pattern": r'<a class="title" href="([^"]+)"',
        "pagination": "/{page}",
    },
}


def get_output_dir(output_dir: str | None, create: bool = True) -> Path:
    """Get output directory path, creating it if needed."""
    if output_dir:
        out_dir = Path(output_dir)
        if create:
            out_dir.mkdir(parents=True, exist_ok=True)
    else:
        out_dir = Path.cwd()
    return out_dir


def get_format_string(max_height: int = DEFAULT_MAX_HEIGHT) -> str:
    """Build yt-dlp format string for given max height."""
    return f"bestvideo[height<={max_height}]+bestaudio/best[height<={max_height}]"


def get_default_ytdlp_args(max_height: int = DEFAULT_MAX_HEIGHT) -> list:
    """Get default yt-dlp args for passthrough mode."""
    return [
        "--write-auto-subs",
        "--embed-subs",
        "--sub-langs",
        DEFAULT_SUB_LANGS,
        "--ignore-errors",
        "-f",
        get_format_string(max_height),
        "--merge-output-format",
        "mp4",
    ]


class DurationType(click.ParamType):
    """Custom Click type for duration parsing."""

    name = "duration"

    def convert(self, value, param, ctx):
        if value is None:
            return None

        try:
            return float(value)
        except (ValueError, TypeError):
            pass

        value = str(value).strip().lower()
        pattern = r"(?:(\d+(?:\.\d+)?)h)?(?:(\d+(?:\.\d+)?)m)?(?:(\d+(?:\.\d+)?)s)?"
        match = re.fullmatch(pattern, value)

        if not match or not any(match.groups()):
            self.fail(
                f"Invalid duration format: '{value}'. "
                "Use formats like: 5m30s, 1h30m, 90s, 2m, or plain seconds",
                param,
                ctx,
            )

        hours = float(match.group(1) or 0)
        minutes = float(match.group(2) or 0)
        seconds = float(match.group(3) or 0)

        return hours * 3600 + minutes * 60 + seconds


DURATION = DurationType()


def format_duration(seconds):
    """Format seconds as human-readable duration string."""
    if seconds < 60:
        return f"{seconds:.1f}s"
    elif seconds < 3600:
        mins = int(seconds // 60)
        secs = seconds % 60
        if secs > 0:
            return f"{mins}m{secs:.0f}s"
        return f"{mins}m"
    else:
        hours = int(seconds // 3600)
        mins = int((seconds % 3600) // 60)
        secs = seconds % 60
        result = f"{hours}h"
        if mins > 0:
            result += f"{mins}m"
        if secs > 0:
            result += f"{secs:.0f}s"
        return result


def get_video_duration(file_path):
    """Get video duration in seconds using ffprobe"""
    cmd = [
        "ffprobe",
        "-v",
        "error",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        str(file_path),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        click.echo(f"Error getting duration for {file_path}: {result.stderr}", err=True)
        return None
    return float(result.stdout.strip())


def split_single_video(
    input_file, segment_duration, skip_start=0, skip_end=0, output_dir=None, cleanup=False
):
    """Split a video file into segments"""
    input_path = Path(input_file)

    if not input_path.exists():
        click.echo(f"Error: File not found: {input_file}", err=True)
        return False

    total_duration = get_video_duration(input_path)
    if total_duration is None:
        return False

    effective_start = skip_start
    effective_end = total_duration - skip_end
    effective_duration = effective_end - effective_start

    if effective_duration <= 0:
        click.echo(
            f"Error: Skip values exceed video duration ({format_duration(total_duration)})",
            err=True,
        )
        return False

    if output_dir:
        out_dir = Path(output_dir)
        out_dir.mkdir(parents=True, exist_ok=True)
    else:
        out_dir = input_path.parent

    num_segments = int(effective_duration // segment_duration)
    if effective_duration % segment_duration > 0:
        num_segments += 1

    click.echo(
        f"Splitting {input_path.name} into {num_segments} segments of {format_duration(segment_duration)} each"
    )
    click.echo(f"  Total duration: {format_duration(total_duration)}")
    click.echo(f"  Skip start: {format_duration(skip_start)}, Skip end: {format_duration(skip_end)}")
    click.echo(f"  Effective duration: {format_duration(effective_duration)}")

    stem = input_path.stem
    suffix = input_path.suffix

    for i in range(num_segments):
        start_time = effective_start + (i * segment_duration)
        if i == num_segments - 1:
            duration = effective_end - start_time
        else:
            duration = segment_duration

        output_file = out_dir / f"{stem}_part{i+1:03d}{suffix}"

        cmd = [
            "ffmpeg",
            "-y",
            "-ss",
            str(start_time),
            "-i",
            str(input_path),
            "-t",
            str(duration),
            "-c",
            "copy",
            "-avoid_negative_ts",
            "1",
            str(output_file),
        ]

        click.echo(
            f"  Creating {output_file.name} (start: {format_duration(start_time)}, duration: {format_duration(duration)})"
        )
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            click.echo(f"Error creating segment: {result.stderr}", err=True)
            return False

    click.echo(f"Successfully created {num_segments} segments")

    if cleanup:
        input_path.unlink()
        click.echo(f"Removed source file: {input_path.name}")

    return True


def split_path(
    path,
    segment_duration,
    skip_start=0,
    skip_end=0,
    output_dir=None,
    cleanup=False,
    recursive=True,
    extensions=None,
):
    """Split video file(s) - handles both single files and directories"""
    input_path = Path(path)

    if not input_path.exists():
        click.echo(f"Error: Path not found: {path}", err=True)
        return False

    if input_path.is_file():
        return split_single_video(
            input_path, segment_duration, skip_start, skip_end, output_dir, cleanup
        )

    if extensions is None:
        extensions = [".mp4", ".mkv", ".avi", ".mov", ".webm", ".m4v"]

    if recursive:
        files = []
        for ext in extensions:
            files.extend(input_path.rglob(f"*{ext}"))
    else:
        files = []
        for ext in extensions:
            files.extend(input_path.glob(f"*{ext}"))

    part_pattern = re.compile(r"_part\d{3}\.")
    files = [f for f in files if not part_pattern.search(f.name)]

    if not files:
        click.echo(f"No video files found in {path}")
        return True

    click.echo(f"Found {len(files)} video file(s) to process")

    success = True
    for video_file in sorted(files):
        click.echo(f"\nProcessing: {video_file}")
        if not split_single_video(
            video_file, segment_duration, skip_start, skip_end, cleanup=cleanup
        ):
            success = False

    return success


def run_yt_dlp(args, capture_output=False):
    """Run yt-dlp with given arguments"""
    cmd = ["yt-dlp"] + list(args)
    if capture_output:
        return subprocess.run(cmd, text=True, stdout=subprocess.PIPE)
    return subprocess.run(cmd)


def run_gallery_dl(args):
    """Run gallery-dl with given arguments"""
    cmd = ["gallery-dl"] + list(args)
    return subprocess.run(cmd)


def download_with_split(
    url, segment_duration, skip_start=0, skip_end=0, output_dir=None, extra_args=None
):
    """Download video using yt-dlp and split into segments"""
    out_dir = get_output_dir(output_dir)
    output_template = str(out_dir / "%(title)s.%(ext)s")

    click.echo(f"Downloading video from: {url}")
    cmd_args = [
        "--yes-playlist",
        "-f",
        "mp4/best[ext=mp4]/best",
        "-o",
        output_template,
        "--print",
        "after_move:filepath",
    ]

    if extra_args:
        cmd_args.extend(extra_args)

    cmd_args.append(url)

    result = run_yt_dlp(cmd_args, capture_output=True)
    if result.returncode != 0:
        click.echo("Error downloading video", err=True)
        return False

    downloaded_files = [
        line.strip()
        for line in result.stdout.strip().split("\n")
        if line.strip() and Path(line.strip()).exists()
    ]

    if not downloaded_files:
        click.echo("Error: No files downloaded", err=True)
        return False

    click.echo(f"Downloaded {len(downloaded_files)} video(s)")

    success = True
    for downloaded_file in downloaded_files:
        click.echo(f"\nProcessing: {downloaded_file}")
        if not split_single_video(
            downloaded_file, segment_duration, skip_start, skip_end, output_dir, cleanup=True
        ):
            success = False

    return success


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


def batch_download_impl(url_file=None, output_dir=None, embed_subs=True, max_height=DEFAULT_MAX_HEIGHT):
    """Download videos from a list file, removing successfully downloaded URLs"""
    if url_file is None:
        url_file = DEFAULT_URL_FILE

    url_path = Path(url_file)
    if not url_path.exists():
        click.echo(f"No URLs to process: {url_file} not found")
        return True

    success_count = 0
    total_count = 0

    while True:
        with open(url_path, "r") as f:
            urls = [
                line.strip()
                for line in f
                if line.strip() and not line.strip().startswith("#")
            ]

        if not urls:
            break

        url = urls[0]
        total_count += 1

        click.echo(f"Downloading: {url}")

        out_dir = get_output_dir(output_dir)
        output_template = str(out_dir / "%(title)s.%(ext)s")

        cmd_args = []
        if embed_subs:
            cmd_args.extend(["--write-auto-subs", "--embed-subs", "--sub-langs", DEFAULT_SUB_LANGS])

        cmd_args.extend(["-f", get_format_string(max_height), "-o", output_template, url])

        result = run_yt_dlp(cmd_args)
        if result.returncode == 0:
            click.echo(f"Successfully downloaded: {url}")
            remove_url_from_file(url, url_file)
            click.echo(f"Removed URL from list: {url}")
            success_count += 1
        else:
            click.echo(f"Failed to download: {url}")
            break

    if total_count > 0:
        click.echo(f"Processing complete. {success_count}/{total_count} URLs downloaded successfully")

    return success_count == total_count


def extract_urls_from_page(page_url, pattern):
    """Extract video URLs from a page using curl and regex pattern"""
    cmd = ["curl", "-sL", page_url]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        click.echo(f"Error fetching page {page_url}: {result.stderr}", err=True)
        return []

    matches = re.findall(pattern, result.stdout)
    return matches


def get_playlist_urls(url):
    """Extract individual video URLs from a playlist using yt-dlp"""
    cmd = ["yt-dlp", "--flat-playlist", "--print", "url", url]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return None
    urls = [line.strip() for line in result.stdout.strip().split("\n") if line.strip()]
    return urls if urls else None


def get_title(url):
    """Get media title using yt-dlp, fallback to gallery-dl"""
    cmd = ["yt-dlp", "--print", "title", "--no-download", url]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0 and result.stdout.strip():
        return result.stdout.strip()

    cmd = ["gallery-dl", "--dump-json", url]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        try:
            for line in result.stdout.strip().split("\n"):
                if line.strip():
                    data = json.loads(line)
                    if isinstance(data, list) and len(data) > 1:
                        meta = data[1] if isinstance(data[1], dict) else {}
                        return meta.get("title") or meta.get("album") or meta.get("filename", "")
        except json.JSONDecodeError:
            pass

    return None


def find_existing_file_by_url(url, search_dirs):
    """Find an existing downloaded file by checking yt-dlp or gallery-dl's expected filename"""
    # Try yt-dlp first
    cmd = ["yt-dlp", "--print", "filename", "-o", "%(title)s.%(ext)s", "--no-download", url]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0 and result.stdout.strip():
        expected_filename = result.stdout.strip()
        for search_dir in search_dirs:
            candidate = Path(search_dir) / expected_filename
            if candidate.exists():
                return candidate

    # Try gallery-dl
    cmd = ["gallery-dl", "--dump-json", url]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        try:
            for line in result.stdout.strip().split("\n"):
                if line.strip():
                    data = json.loads(line)
                    if isinstance(data, list) and len(data) > 1:
                        meta = data[1] if isinstance(data[1], dict) else {}
                        filename = meta.get("filename")
                        ext = meta.get("extension", "")
                        if filename:
                            expected_filename = f"{filename}.{ext}" if ext else filename
                            for search_dir in search_dirs:
                                candidate = Path(search_dir) / expected_filename
                                if candidate.exists():
                                    return candidate
        except json.JSONDecodeError:
            pass

    return None


def move_or_download_for_page(
    url, page, base_output_dir, all_page_dirs, max_height=DEFAULT_MAX_HEIGHT, split=False,
    segment_duration=DEFAULT_SEGMENT_DURATION, skip_start=0, skip_end=0
):
    """Move existing file to correct page dir or download if not found. Returns (url, success)"""
    base_dir = get_output_dir(base_output_dir, create=False)

    page_dir = base_dir / f"page-{page}"
    page_dir.mkdir(parents=True, exist_ok=True)

    existing_file = find_existing_file_by_url(url, all_page_dirs + [base_dir])

    if existing_file:
        target_path = page_dir / existing_file.name
        if existing_file.parent == page_dir:
            click.echo(f"[SKIP] Already in correct location: {existing_file.name}")
            return (url, True)
        else:
            shutil.move(str(existing_file), str(target_path))
            click.echo(f"[MOVE] {existing_file.parent.name}/{existing_file.name} -> page-{page}/")
            return (url, True)

    return download_single_video(
        url, str(page_dir), max_height, split, segment_duration, skip_start, skip_end
    )


def download_single_video(
    url, output_dir, max_height=DEFAULT_MAX_HEIGHT, split=False,
    segment_duration=DEFAULT_SEGMENT_DURATION, skip_start=0, skip_end=0
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
            # Find the downloaded file by checking what's new in the directory
            # gallery-dl doesn't have a --print option, so we rely on the download succeeding
            return (url, True)
        return (url, False)

    if not split:
        return (url, True)

    if downloaded_file and Path(downloaded_file).exists():
        success = split_single_video(
            downloaded_file, segment_duration, skip_start, skip_end, output_dir, cleanup=True
        )
        return (url, success)

    return (url, False)


def scrape_and_download_impl(
    base_url,
    start_page=1,
    end_page=None,
    pattern=None,
    pagination=None,
    workers=4,
    output_dir=None,
    max_height=DEFAULT_MAX_HEIGHT,
    split=False,
    segment_duration=DEFAULT_SEGMENT_DURATION,
    skip_start=0,
    skip_end=0,
    url_filter=None,
    url_exclude=None,
    split_pages=False,
):
    """Scrape and download page by page"""
    if pattern is None:
        pattern = SITE_CONFIGS["3"]["pattern"]
    if pagination is None:
        pagination = SITE_CONFIGS["3"]["pagination"]

    seen = set()
    page = start_page
    total_success = 0
    total_failed = 0

    base_dir = get_output_dir(output_dir, create=False)

    # Disable split_pages if only 1 page requested
    if end_page is not None and end_page == start_page:
        split_pages = False

    all_page_dirs = []
    if split_pages:
        for p in base_dir.glob("page-*"):
            if p.is_dir():
                all_page_dirs.append(p)

    click.echo(f"Scraping and downloading from {base_url}")
    page_range = f"{start_page}-{end_page}" if end_page else f"{start_page}-∞"
    click.echo(f"Pages: {page_range}")
    click.echo(f"Split videos: {'enabled' if split else 'disabled'}")
    if split:
        click.echo(f"  Segment duration: {format_duration(segment_duration)}")
    click.echo(f"Split by pages: {'enabled' if split_pages else 'disabled'}")
    click.echo(f"Workers: {workers}\n")

    while True:
        if page == 1:
            page_url = base_url.rstrip("/")
        else:
            page_url = base_url.rstrip("/") + pagination.format(page=page)

        click.echo(f"=== Page {page}: {page_url} ===")
        urls = extract_urls_from_page(page_url, pattern)

        if not urls:
            click.echo("No URLs found, stopping\n")
            break

        new_urls = [url for url in urls if url not in seen]
        for url in new_urls:
            seen.add(url)

        click.echo(f"Found {len(urls)} URLs, {len(new_urls)} new")

        if (url_filter or url_exclude) and new_urls:
            click.echo("Fetching titles for filtering...")
            url_titles = {}
            with ThreadPoolExecutor(max_workers=workers) as executor:
                futures = {executor.submit(get_title, url): url for url in new_urls}
                for future in as_completed(futures):
                    url = futures[future]
                    title = future.result()
                    url_titles[url] = title or ""

            if url_filter:
                filter_re = re.compile(url_filter, re.IGNORECASE)
                before_count = len(new_urls)
                new_urls = [url for url in new_urls if filter_re.search(url_titles.get(url, ""))]
                click.echo(f"Filter '{url_filter}': {before_count} -> {len(new_urls)} URLs")

            if url_exclude:
                exclude_re = re.compile(url_exclude, re.IGNORECASE)
                before_count = len(new_urls)
                new_urls = [url for url in new_urls if not exclude_re.search(url_titles.get(url, ""))]
                click.echo(f"Exclude '{url_exclude}': {before_count} -> {len(new_urls)} URLs")

        click.echo(f"Processing {len(new_urls)} URLs\n")

        if new_urls:
            page_success = 0
            page_failed = []

            if split_pages:
                page_dir = base_dir / f"page-{page}"
                if page_dir not in all_page_dirs:
                    all_page_dirs.append(page_dir)

                with ThreadPoolExecutor(max_workers=workers) as executor:
                    futures = {
                        executor.submit(
                            move_or_download_for_page,
                            url,
                            page,
                            output_dir,
                            [str(d) for d in all_page_dirs],
                            max_height,
                            split,
                            segment_duration,
                            skip_start,
                            skip_end,
                        ): url
                        for url in new_urls
                    }

                    for future in as_completed(futures):
                        url, success = future.result()
                        if success:
                            page_success += 1
                            click.echo(f"[{page_success}/{len(new_urls)}] Completed: {url}")
                        else:
                            page_failed.append(url)
                            click.echo(f"[FAILED] {url}")
            else:
                with ThreadPoolExecutor(max_workers=workers) as executor:
                    futures = {
                        executor.submit(
                            download_single_video,
                            url,
                            output_dir,
                            max_height,
                            split,
                            segment_duration,
                            skip_start,
                            skip_end,
                        ): url
                        for url in new_urls
                    }

                    for future in as_completed(futures):
                        url, success = future.result()
                        if success:
                            page_success += 1
                            click.echo(f"[{page_success}/{len(new_urls)}] Completed: {url}")
                        else:
                            page_failed.append(url)
                            click.echo(f"[FAILED] {url}")

            total_success += page_success
            total_failed += len(page_failed)
            click.echo(f"\nPage {page} done: {page_success}/{len(new_urls)} successful\n")

        if end_page and page >= end_page:
            break

        page += 1

    click.echo(f"=== All done: {total_success} successful, {total_failed} failed ===")
    return total_failed == 0


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
                    click.echo("\nyt-dlp failed, trying gallery-dl as fallback...\n", err=True)
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
@click.option("-d", "--duration", type=DURATION, default=DEFAULT_SEGMENT_DURATION, help=f"Segment duration (default: {DEFAULT_SEGMENT_DURATION}s)")
@click.option("--skip-start", type=DURATION, default=0, help="Skip from start (default: 0)")
@click.option("--skip-end", type=DURATION, default=0, help="Skip from end (default: 0)")
def split(url, output_dir, duration, skip_start, skip_end):
    """Download video and split into segments."""
    success = download_with_split(url, duration, skip_start, skip_end, output_dir)
    sys.exit(0 if success else 1)


@cli.command()
@click.argument("url")
@click.option("-o", "--output-dir", help="Output directory")
@click.option("-w", "--workers", type=int, default=1, help="Parallel workers for playlists (default: 1)")
@click.option("--split", "do_split", is_flag=True, help="Split videos after download")
@click.option("-d", "--duration", type=DURATION, default=DEFAULT_SEGMENT_DURATION, help=f"Segment duration if splitting (default: {DEFAULT_SEGMENT_DURATION}s)")
@click.option("--skip-start", type=DURATION, default=0, help="Skip from start if splitting (default: 0)")
@click.option("--skip-end", type=DURATION, default=0, help="Skip from end if splitting (default: 0)")
@click.option("--max-height", type=int, default=DEFAULT_MAX_HEIGHT, help=f"Maximum video height (default: {DEFAULT_MAX_HEIGHT})")
def download(url, output_dir, workers, do_split, duration, skip_start, skip_end, max_height):
    """Download video(s) from URL or playlist.

    For playlist URLs, use -w/--workers to download videos in parallel.
    Use --split to split videos into segments after download.
    """
    split = do_split

    if workers > 1:
        click.echo(f"Extracting video URLs from playlist...")
        urls = get_playlist_urls(url)

        if not urls:
            click.echo("No videos found or not a playlist, downloading as single video")
            if split:
                success = download_with_split(url, duration, skip_start, skip_end, output_dir)
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
            success = download_with_split(url, duration, skip_start, skip_end, output_dir)
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
@click.option("-r/-R", "--recursive/--no-recursive", default=True, help="Process subdirectories")
@click.option("-e", "--extensions", multiple=True, help="File extensions to process")
@click.option("-d", "--duration", type=DURATION, default=DEFAULT_SEGMENT_DURATION, help=f"Segment duration (default: {DEFAULT_SEGMENT_DURATION}s)")
@click.option("--skip-start", type=DURATION, default=0, help="Skip from start (default: 0)")
@click.option("--skip-end", type=DURATION, default=0, help="Skip from end (default: 0)")
def process(path, output_dir, cleanup, recursive, extensions, duration, skip_start, skip_end):
    """Split local video file(s)."""
    exts = None
    if extensions:
        exts = [f".{e.lstrip('.')}" for e in extensions]
    success = split_path(path, duration, skip_start, skip_end, output_dir, cleanup, recursive, exts)
    sys.exit(0 if success else 1)


@cli.command()
@click.option("-f", "--file", "url_file", default=DEFAULT_URL_FILE, help=f"URL list file (default: {DEFAULT_URL_FILE})")
@click.option("-o", "--output-dir", help="Output directory")
@click.option("--embed-subs/--no-embed-subs", default=True, help="Embed subtitles")
@click.option("--max-height", type=int, default=DEFAULT_MAX_HEIGHT, help=f"Maximum video height (default: {DEFAULT_MAX_HEIGHT})")
def batch(url_file, output_dir, embed_subs, max_height):
    """Download videos from a URL list file."""
    success = batch_download_impl(url_file, output_dir, embed_subs, max_height)
    sys.exit(0 if success else 1)


@cli.command()
@click.argument("url")
@click.option("-o", "--output-dir", help="Output directory")
@click.option("--start-page", type=int, default=1, help="Starting page (default: 1)")
@click.option("--end-page", type=int, help="Ending page")
@click.option("-s", "--site", type=click.Choice(list(SITE_CONFIGS.keys())), help="Use preset config for site")
@click.option("-p", "--pattern", help="Custom regex pattern for URLs (overrides --site)")
@click.option("-f", "--filter", "url_filter", help="Regex to filter by video title (case-insensitive, include matching)")
@click.option("-x", "--exclude", "url_exclude", help="Regex to filter by video title (case-insensitive, exclude matching)")
@click.option("-w", "--workers", type=int, default=4, help="Parallel workers (default: 4)")
@click.option("--max-height", type=int, default=DEFAULT_MAX_HEIGHT, help=f"Maximum video height (default: {DEFAULT_MAX_HEIGHT})")
@click.option("--split", "do_split", is_flag=True, help="Split videos after download")
@click.option("--split-pages/--no-split-pages", default=True, help="Organize files into page-N directories (default: enabled)")
@click.option("-d", "--duration", type=DURATION, default=DEFAULT_SEGMENT_DURATION, help=f"Segment duration (default: {DEFAULT_SEGMENT_DURATION}s)")
@click.option("--skip-start", type=DURATION, default=0, help="Skip from start (default: 0)")
@click.option("--skip-end", type=DURATION, default=0, help="Skip from end (default: 0)")
def scrape(url, output_dir, start_page, end_page, site, pattern, url_filter, url_exclude, workers, max_height, do_split, split_pages, duration, skip_start, skip_end):
    """Scrape paginated pages and download videos.

    Use --site to select a preset config, or --pattern for custom regex.
    Use --filter to include only videos with titles matching a pattern (e.g., -f "pink").
    Use --exclude to skip videos with titles matching a pattern.
    Use --split-pages to organize downloads into page-N directories. Re-running
    with --split-pages will move existing files to their correct page directories.
    """
    pagination = None
    if site:
        config = SITE_CONFIGS.get(site, {})
        if pattern is None:
            pattern = config.get("pattern")
        pagination = config.get("pagination")
    success = scrape_and_download_impl(
        url, start_page, end_page, pattern, pagination, workers, output_dir, max_height, do_split, duration, skip_start, skip_end,
        url_filter=url_filter, url_exclude=url_exclude, split_pages=split_pages
    )
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    cli()
