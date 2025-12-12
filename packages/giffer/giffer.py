#!/usr/bin/env python3

import argparse
import re
import subprocess
import sys
from pathlib import Path

DEFAULT_URL_FILE = ".list.txt"


def parse_duration(value):
    """Parse human-readable duration string to seconds.

    Supports formats like: 5m30s, 1h30m, 90s, 2m, 30, 1h2m3s
    Plain numbers are treated as seconds.
    """
    if value is None:
        return None

    # If it's already a number, return it
    try:
        return float(value)
    except (ValueError, TypeError):
        pass

    value = str(value).strip().lower()

    # Parse hours, minutes, seconds
    pattern = r'(?:(\d+(?:\.\d+)?)h)?(?:(\d+(?:\.\d+)?)m)?(?:(\d+(?:\.\d+)?)s)?'
    match = re.fullmatch(pattern, value)

    if not match or not any(match.groups()):
        raise argparse.ArgumentTypeError(
            f"Invalid duration format: '{value}'. "
            "Use formats like: 5m30s, 1h30m, 90s, 2m, or plain seconds (e.g., 90)"
        )

    hours = float(match.group(1) or 0)
    minutes = float(match.group(2) or 0)
    seconds = float(match.group(3) or 0)

    return hours * 3600 + minutes * 60 + seconds


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
        "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        str(file_path)
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error getting duration for {file_path}: {result.stderr}", file=sys.stderr)
        return None
    return float(result.stdout.strip())


def split_single_video(input_file, segment_duration, skip_start=0, skip_end=0, output_dir=None, cleanup=False):
    """Split a video file into segments"""
    input_path = Path(input_file)

    if not input_path.exists():
        print(f"Error: File not found: {input_file}", file=sys.stderr)
        return False

    # Get total duration
    total_duration = get_video_duration(input_path)
    if total_duration is None:
        return False

    # Calculate effective duration
    effective_start = skip_start
    effective_end = total_duration - skip_end
    effective_duration = effective_end - effective_start

    if effective_duration <= 0:
        print(f"Error: Skip values exceed video duration ({format_duration(total_duration)})", file=sys.stderr)
        return False

    # Determine output directory
    if output_dir:
        out_dir = Path(output_dir)
        out_dir.mkdir(parents=True, exist_ok=True)
    else:
        out_dir = input_path.parent

    # Calculate number of segments
    num_segments = int(effective_duration // segment_duration)
    if effective_duration % segment_duration > 0:
        num_segments += 1

    print(f"Splitting {input_path.name} into {num_segments} segments of {format_duration(segment_duration)} each")
    print(f"  Total duration: {format_duration(total_duration)}")
    print(f"  Skip start: {format_duration(skip_start)}, Skip end: {format_duration(skip_end)}")
    print(f"  Effective duration: {format_duration(effective_duration)}")

    stem = input_path.stem
    suffix = input_path.suffix

    for i in range(num_segments):
        start_time = effective_start + (i * segment_duration)
        # For the last segment, use remaining duration
        if i == num_segments - 1:
            duration = effective_end - start_time
        else:
            duration = segment_duration

        output_file = out_dir / f"{stem}_part{i+1:03d}{suffix}"

        cmd = [
            "ffmpeg",
            "-y",
            "-ss", str(start_time),
            "-i", str(input_path),
            "-t", str(duration),
            "-c", "copy",
            "-avoid_negative_ts", "1",
            str(output_file)
        ]

        print(f"  Creating {output_file.name} (start: {format_duration(start_time)}, duration: {format_duration(duration)})")
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Error creating segment: {result.stderr}", file=sys.stderr)
            return False

    print(f"Successfully created {num_segments} segments")

    if cleanup:
        input_path.unlink()
        print(f"Removed source file: {input_path.name}")

    return True


def split_path(path, segment_duration, skip_start=0, skip_end=0, output_dir=None, cleanup=False, recursive=True, extensions=None):
    """Split video file(s) - handles both single files and directories"""
    input_path = Path(path)

    if not input_path.exists():
        print(f"Error: Path not found: {path}", file=sys.stderr)
        return False

    # Single file
    if input_path.is_file():
        return split_single_video(input_path, segment_duration, skip_start, skip_end, output_dir, cleanup)

    # Directory
    if extensions is None:
        extensions = ['.mp4', '.mkv', '.avi', '.mov', '.webm', '.m4v']

    # Find video files
    if recursive:
        files = []
        for ext in extensions:
            files.extend(input_path.rglob(f"*{ext}"))
    else:
        files = []
        for ext in extensions:
            files.extend(input_path.glob(f"*{ext}"))

    # Filter out already split files (those with _partXXX pattern)
    part_pattern = re.compile(r'_part\d{3}\.')
    files = [f for f in files if not part_pattern.search(f.name)]

    if not files:
        print(f"No video files found in {path}")
        return True

    print(f"Found {len(files)} video file(s) to process")

    success = True
    for video_file in sorted(files):
        print(f"\nProcessing: {video_file}")
        if not split_single_video(video_file, segment_duration, skip_start, skip_end, cleanup=cleanup):
            success = False

    return success


def download_and_split(url, segment_duration, skip_start=0, skip_end=0, output_dir=None):
    """Download video(s) using yt-dlp and split them (supports playlists)"""
    if output_dir:
        out_dir = Path(output_dir)
        out_dir.mkdir(parents=True, exist_ok=True)
    else:
        out_dir = Path.cwd()

    # Download with yt-dlp
    output_template = str(out_dir / "%(title)s.%(ext)s")

    print(f"Downloading video from: {url}")
    cmd = [
        "yt-dlp",
        "--yes-playlist",
        "-f", "mp4/best[ext=mp4]/best",
        "-o", output_template,
        "--print", "after_move:filepath",
        url
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error downloading video: {result.stderr}", file=sys.stderr)
        return False

    # Get all downloaded files (supports playlists)
    downloaded_files = [
        line.strip() for line in result.stdout.strip().split('\n')
        if line.strip() and Path(line.strip()).exists()
    ]

    if not downloaded_files:
        print("Error: No files downloaded", file=sys.stderr)
        return False

    print(f"Downloaded {len(downloaded_files)} video(s)")

    # Split each downloaded video
    success = True
    for downloaded_file in downloaded_files:
        print(f"\nProcessing: {downloaded_file}")
        if not split_single_video(downloaded_file, segment_duration, skip_start, skip_end, output_dir, cleanup=True):
            success = False

    return success


def download_only(url, output_dir=None, embed_subs=True, max_height=1080):
    """Download video using yt-dlp without splitting"""
    if output_dir:
        out_dir = Path(output_dir)
        out_dir.mkdir(parents=True, exist_ok=True)
    else:
        out_dir = Path.cwd()

    output_template = str(out_dir / "%(title)s.%(ext)s")

    print(f"Downloading video from: {url}")
    cmd = ["yt-dlp"]

    if embed_subs:
        cmd.extend(["--write-auto-subs", "--embed-subs"])

    cmd.extend([
        "--format", f"best[height<={max_height}]",
        "-o", output_template,
        url
    ])

    result = subprocess.run(cmd, capture_output=False)
    return result.returncode == 0


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
        print(f"Warning: Could not remove URL from file: {e}", file=sys.stderr)


def batch_download(url_file=None, output_dir=None, embed_subs=True, max_height=1080):
    """Download videos from a list file, removing successfully downloaded URLs"""
    if url_file is None:
        url_file = DEFAULT_URL_FILE

    url_path = Path(url_file)
    if not url_path.exists():
        print(f"No URLs to process: {url_file} not found")
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

        print(f"Downloading: {url}")

        if download_only(url, output_dir, embed_subs, max_height):
            print(f"Successfully downloaded: {url}")
            remove_url_from_file(url, url_file)
            print(f"Removed URL from list: {url}")
            success_count += 1
        else:
            print(f"Failed to download: {url}")
            break

    if total_count > 0:
        print(f"Processing complete. {success_count}/{total_count} URLs downloaded successfully")

    return success_count == total_count


def main():
    parser = argparse.ArgumentParser(
        description="Video download and splitting tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  giffer download "https://youtube.com/watch?v=xxx" --duration 30s
  giffer download "https://youtube.com/watch?v=xxx" -d 2m30s
  giffer process video.mp4 --duration 1m --skip-start 5s --skip-end 10s
  giffer process ./videos --duration 45s --recursive
  giffer batch                          # Download from .list.txt
  giffer batch --file urls.txt          # Download from custom file

Duration formats: 30 (seconds), 30s, 2m, 1m30s, 1h, 1h30m, 1h2m3s
"""
    )
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Common arguments
    def add_common_args(p):
        p.add_argument("-d", "--duration", type=parse_duration, default=10,
                       help="Segment duration (e.g., 10, 30s, 2m, 1m30s) (default: 10s)")
        p.add_argument("--skip-start", type=parse_duration, default=0,
                       help="Duration to skip from start (e.g., 5s, 1m) (default: 0)")
        p.add_argument("--skip-end", type=parse_duration, default=0,
                       help="Duration to skip from end (e.g., 10s, 30s) (default: 0)")

    # Download command
    download_parser = subparsers.add_parser("download", help="Download video and split it")
    download_parser.add_argument("url", help="Video URL to download")
    download_parser.add_argument("-o", "--output-dir", help="Output directory")
    add_common_args(download_parser)

    # Process command (handles both files and directories)
    process_parser = subparsers.add_parser("process", help="Process local video file(s)")
    process_parser.add_argument("path", help="Video file or directory to process")
    process_parser.add_argument("-o", "--output-dir", help="Output directory (default: same as input)")
    process_parser.add_argument("--cleanup", action="store_true",
                                help="Remove source file(s) after splitting")
    process_parser.add_argument("-r", "--recursive", action="store_true", default=True,
                                help="Process subdirectories recursively (default: True)")
    process_parser.add_argument("--no-recursive", action="store_false", dest="recursive",
                                help="Do not process subdirectories")
    process_parser.add_argument("-e", "--extensions", nargs="+",
                                help="File extensions to process (default: mp4 mkv avi mov webm m4v)")
    add_common_args(process_parser)

    # Batch command (from download-youtube)
    batch_parser = subparsers.add_parser("batch", help="Download videos from a URL list file")
    batch_parser.add_argument("-f", "--file", default=DEFAULT_URL_FILE,
                              help=f"URL list file (default: {DEFAULT_URL_FILE})")
    batch_parser.add_argument("-o", "--output-dir", help="Output directory")
    batch_parser.add_argument("--embed-subs", action="store_true", default=True,
                              help="Embed subtitles (default: True)")
    batch_parser.add_argument("--no-embed-subs", action="store_false", dest="embed_subs",
                              help="Do not embed subtitles")
    batch_parser.add_argument("--max-height", type=int, default=1080,
                              help="Maximum video height (default: 1080)")

    args = parser.parse_args()

    if args.command == "download":
        success = download_and_split(
            args.url,
            args.duration,
            args.skip_start,
            args.skip_end,
            args.output_dir
        )
    elif args.command == "process":
        extensions = None
        if args.extensions:
            extensions = [f".{e.lstrip('.')}" for e in args.extensions]
        success = split_path(
            args.path,
            args.duration,
            args.skip_start,
            args.skip_end,
            args.output_dir,
            args.cleanup,
            args.recursive,
            extensions
        )
    elif args.command == "batch":
        success = batch_download(
            args.file,
            args.output_dir,
            args.embed_subs,
            args.max_height
        )
    else:
        parser.print_help()
        sys.exit(0)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
