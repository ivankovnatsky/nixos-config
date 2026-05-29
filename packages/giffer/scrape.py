"""Scraping, URL extraction, and paginated download functions."""

import json
import re
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import click

from constants import DEFAULT_MAX_HEIGHT, DEFAULT_SEGMENT_DURATION, SITE_CONFIGS
from download import download_single_video
from utils import format_duration, get_output_dir


def extract_urls_from_page(page_url, pattern):
    """Extract video URLs from a page using curl and regex pattern.

    Returns tuple of (urls, redirected) where redirected is True if page
    redirected to a different location (indicating page doesn't exist).
    """
    cmd = ["curl", "-sI", page_url]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        click.echo(f"Error fetching page {page_url}: {result.stderr}", err=True)
        return [], False

    # Check for redirect to different page (site returns 301 for non-existent pages)
    for line in result.stdout.split("\n"):
        if line.lower().startswith("location:"):
            redirect_url = line.split(":", 1)[1].strip()
            # Normalize URLs for comparison (remove trailing slash, http vs https)
            norm_page = (
                page_url.rstrip("/").replace("https://", "").replace("http://", "")
            )
            norm_redirect = (
                redirect_url.rstrip("/").replace("https://", "").replace("http://", "")
            )
            if norm_redirect != norm_page:
                return [], True

    # Fetch actual content
    cmd = ["curl", "-sL", page_url]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        click.echo(f"Error fetching page {page_url}: {result.stderr}", err=True)
        return [], False

    matches = re.findall(pattern, result.stdout)
    return matches, False


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
                        return (
                            meta.get("title")
                            or meta.get("album")
                            or meta.get("filename", "")
                        )
        except json.JSONDecodeError:
            pass

    return None


def find_existing_file_by_url(url, search_dirs):
    """Find an existing downloaded file by checking yt-dlp or gallery-dl's expected filename"""
    # Try yt-dlp first
    cmd = [
        "yt-dlp",
        "--print",
        "filename",
        "-o",
        "%(title)s.%(ext)s",
        "--no-download",
        url,
    ]
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


def build_filename_index(search_dirs):
    """Build index of existing filenames from search directories (recursive)."""
    index = {}
    for search_dir in search_dirs:
        dir_path = Path(search_dir)
        if not dir_path.exists():
            continue
        for f in dir_path.rglob("*"):
            if f.is_file() and f.suffix and f.name not in index:
                index[f.name] = f
    return index


def get_expected_filename(url):
    """Get expected filename for a URL without downloading."""
    cmd = [
        "yt-dlp",
        "--print",
        "filename",
        "-o",
        "%(title)s.%(ext)s",
        "--no-download",
        url,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0 and result.stdout.strip():
        return result.stdout.strip()
    return None


def move_or_download_for_page(
    url,
    page,
    base_output_dir,
    all_page_dirs,
    max_height=DEFAULT_MAX_HEIGHT,
    split=False,
    segment_duration=DEFAULT_SEGMENT_DURATION,
    skip_start=0,
    skip_end=0,
    page_width=1,
):
    """Move existing file to correct page dir or download if not found. Returns (url, success)"""
    base_dir = get_output_dir(base_output_dir, create=False)

    page_name = f"page-{page:0{page_width}d}"
    page_dir = base_dir / page_name
    page_dir.mkdir(parents=True, exist_ok=True)

    existing_file = find_existing_file_by_url(url, all_page_dirs + [base_dir])

    if existing_file:
        target_path = page_dir / existing_file.name
        if existing_file.parent == page_dir:
            click.echo(f"[SKIP] Already in correct location: {existing_file.name}")
            return (url, True)
        else:
            shutil.move(str(existing_file), str(target_path))
            click.echo(
                f"[MOVE] {existing_file.parent.name}/{existing_file.name} -> {page_name}/"
            )
            return (url, True)

    return download_single_video(
        url, str(page_dir), max_height, split, segment_duration, skip_start, skip_end
    )


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
    search_dirs=None,
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

    page_width = len(str(end_page)) if end_page else 3

    all_page_dirs = []
    if split_pages:
        # Normalize existing page directories to consistent zero-padding
        page_dir_re = re.compile(r"^page-(\d+)$")
        for p in sorted(base_dir.glob("page-*")):
            if not p.is_dir():
                continue
            match = page_dir_re.match(p.name)
            if not match:
                continue
            page_num = int(match.group(1))
            expected_name = f"page-{page_num:0{page_width}d}"
            if p.name != expected_name:
                new_path = p.parent / expected_name
                p.rename(new_path)
                click.echo(f"[RENAME] {p.name} -> {expected_name}")

        for p in base_dir.glob("page-*"):
            if p.is_dir():
                all_page_dirs.append(p)

    filename_index = None
    if search_dirs:
        # Find files that exist outside the output dir
        out_dir_resolved = base_dir.resolve()
        external_files = set()
        for search_dir in search_dirs:
            dir_path = Path(search_dir)
            if not dir_path.exists():
                continue
            for f in dir_path.rglob("*"):
                if not f.is_file() or not f.suffix:
                    continue
                try:
                    f.resolve().relative_to(out_dir_resolved)
                except ValueError:
                    external_files.add(f.name)

        # Clean up duplicates already in output dir
        cleaned = 0
        for f in base_dir.rglob("*"):
            if f.is_file() and f.name in external_files:
                click.echo(f"[CLEANUP] {f.name}")
                f.unlink()
                cleaned += 1
        if cleaned:
            click.echo(f"Cleaned up {cleaned} duplicate(s)")

        # Build filename index after cleanup
        click.echo(f"Building filename index from {len(search_dirs)} search dir(s)...")
        filename_index = build_filename_index(search_dirs)
        click.echo(f"Indexed {len(filename_index)} existing files")

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
        urls, redirected = extract_urls_from_page(page_url, pattern)

        if redirected:
            click.echo("Page redirected (page doesn't exist), stopping\n")
            break

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
                new_urls = [
                    url for url in new_urls if filter_re.search(url_titles.get(url, ""))
                ]
                click.echo(
                    f"Filter '{url_filter}': {before_count} -> {len(new_urls)} URLs"
                )

            if url_exclude:
                exclude_re = re.compile(url_exclude, re.IGNORECASE)
                before_count = len(new_urls)
                new_urls = [
                    url
                    for url in new_urls
                    if not exclude_re.search(url_titles.get(url, ""))
                ]
                click.echo(
                    f"Exclude '{url_exclude}': {before_count} -> {len(new_urls)} URLs"
                )

        click.echo(f"Processing {len(new_urls)} URLs\n")

        if filename_index and new_urls:
            urls_to_download = []
            skipped = 0
            with ThreadPoolExecutor(max_workers=workers) as executor:
                futures = {
                    executor.submit(get_expected_filename, url): url for url in new_urls
                }
                for future in as_completed(futures):
                    url = futures[future]
                    expected = future.result()
                    if expected and expected in filename_index:
                        click.echo(f"[SKIP] Already exists: {filename_index[expected]}")
                        skipped += 1
                    else:
                        urls_to_download.append(url)
            if skipped:
                click.echo(
                    f"Skipped {skipped} existing, downloading {len(urls_to_download)}\n"
                )
            new_urls = urls_to_download

        if new_urls:
            page_success = 0
            page_failed = []

            if split_pages:
                page_dir = base_dir / f"page-{page:0{page_width}d}"
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
                            page_width,
                        ): url
                        for url in new_urls
                    }

                    for future in as_completed(futures):
                        url, success = future.result()
                        if success:
                            page_success += 1
                            click.echo(
                                f"[{page_success}/{len(new_urls)}] Completed: {url}"
                            )
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
                            click.echo(
                                f"[{page_success}/{len(new_urls)}] Completed: {url}"
                            )
                        else:
                            page_failed.append(url)
                            click.echo(f"[FAILED] {url}")

            total_success += page_success
            total_failed += len(page_failed)
            click.echo(
                f"\nPage {page} done: {page_success}/{len(new_urls)} successful\n"
            )

        if end_page and page >= end_page:
            break

        page += 1

    click.echo(f"=== All done: {total_success} successful, {total_failed} failed ===")
    return total_failed == 0
