"""Video splitting and duration functions."""

import re
import subprocess
from pathlib import Path

import click

from utils import format_duration, get_output_dir, run_yt_dlp


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
    input_file,
    segment_duration,
    skip_start=0,
    skip_end=0,
    output_dir=None,
    cleanup=False,
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
    click.echo(
        f"  Skip start: {format_duration(skip_start)}, Skip end: {format_duration(skip_end)}"
    )
    click.echo(f"  Effective duration: {format_duration(effective_duration)}")

    stem = input_path.stem
    suffix = input_path.suffix

    for i in range(num_segments):
        start_time = effective_start + (i * segment_duration)
        if i == num_segments - 1:
            duration = effective_end - start_time
        else:
            duration = segment_duration

        output_file = out_dir / f"{stem}_part{i + 1:03d}{suffix}"

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
            downloaded_file,
            segment_duration,
            skip_start,
            skip_end,
            output_dir,
            cleanup=True,
        ):
            success = False

    return success
