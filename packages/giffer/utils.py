"""Utility functions, types, and runner wrappers for giffer."""

import re
import subprocess
from pathlib import Path

import click

from constants import DEFAULT_MAX_HEIGHT, DEFAULT_SUB_LANGS


def get_output_dir(output_dir, create=True):
    """Get output directory path, creating it if needed."""
    if output_dir:
        out_dir = Path(output_dir)
        if create:
            out_dir.mkdir(parents=True, exist_ok=True)
    else:
        out_dir = Path.cwd()
    return out_dir


def get_format_string(max_height=DEFAULT_MAX_HEIGHT):
    """Build yt-dlp format string for given max height."""
    return f"bestvideo[height<={max_height}]+bestaudio/best[height<={max_height}]/best"


def get_default_ytdlp_args(max_height=DEFAULT_MAX_HEIGHT):
    """Get default yt-dlp args for passthrough mode."""
    return [
        "--check-formats",
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


def detect_extension(file_path):
    """Detect file extension from magic bytes."""
    try:
        with open(file_path, "rb") as f:
            header = f.read(12)
    except (OSError, IOError):
        return None

    if len(header) < 4:
        return None

    if header[:3] == b"\xff\xd8\xff":
        return ".jpg"
    if header[:8] == b"\x89PNG\r\n\x1a\n":
        return ".png"
    if header[:6] in (b"GIF87a", b"GIF89a"):
        return ".gif"
    if header[:4] == b"RIFF" and len(header) >= 12 and header[8:12] == b"WEBP":
        return ".webp"
    if len(header) >= 8 and header[4:8] == b"ftyp":
        return ".mp4"
    if header[:4] == b"\x1aE\xdf\xa3":
        return ".mkv"

    return None


def fix_unknown_extensions(directory, known_files=None):
    """Rename files with .unknown_video extension based on detected type."""
    dir_path = Path(directory)
    for path in dir_path.glob("*.unknown_video"):
        if known_files is not None and path in known_files:
            continue
        ext = detect_extension(path)
        if ext:
            new_path = path.with_suffix(ext)
            path.rename(new_path)
            click.echo(f"Renamed: {path.name} -> {new_path.name}")


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
