"""Scan system logs for errors and alert via Discord webhook."""

import glob
import json
import os
import platform
import re
import subprocess
import time

import click

from discord import send_discord as _send_discord


DEFAULT_PATTERNS = [
    r"(?i)\berror\b",
    r"(?i)\bfatal\b",
    r"(?i)\bpanic\b",
    r"(?i)\bfailed\b",
    r"(?i)\bcrash\b",
]

MAX_DISCORD_LENGTH = 1900


def load_config(path):
    with open(path) as f:
        return json.load(f)


def get_webhook_url(config):
    webhook_file = config.get("discordWebhookFile")
    if webhook_file:
        with open(webhook_file) as f:
            return f.read().strip()
    return None


def matches_patterns(line, patterns):
    return any(p.search(line) for p in patterns)


def load_state(state_file):
    """Load per-file byte offsets from state file."""
    if state_file and os.path.exists(state_file):
        try:
            with open(state_file) as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            pass
    return {}


def save_state(state_file, state):
    """Save per-file byte offsets to state file."""
    if state_file:
        with open(state_file, "w") as f:
            json.dump(state, f)


def scan_journalctl(hours=24):
    """Scan systemd journal for errors (NixOS/Linux)."""
    try:
        result = subprocess.run(
            [
                "journalctl",
                "--since",
                f"{hours} hours ago",
                "-p",
                "err",
                "--no-pager",
                "-q",
            ],
            capture_output=True,
            text=True,
            timeout=60,
        )
        return result.stdout.strip().splitlines() if result.stdout.strip() else []
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return []


def scan_darwin_log(hours=24, predicate=None):
    """Scan macOS unified log for errors."""
    if predicate is None:
        predicate = "messageType == error"
    try:
        result = subprocess.run(
            [
                "log",
                "show",
                "--last",
                f"{hours}h",
                "--predicate",
                predicate,
                "--style",
                "compact",
            ],
            capture_output=True,
            text=True,
            timeout=120,
        )
        lines = result.stdout.strip().splitlines()
        # Skip header lines that log show prints
        return [line for line in lines if line and not line.startswith("Filtering")]
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return []


def scan_files(paths, patterns, state, exclude=None):
    """Scan log files for matching patterns since last read offset."""
    if exclude is None:
        exclude = []
    matches = []
    for pattern in paths:
        for filepath in glob.glob(pattern):
            if not os.path.isfile(filepath):
                continue
            # Skip excluded files (e.g. logscanner's own logs)
            basename = os.path.basename(filepath)
            if any(basename.startswith(ex) for ex in exclude):
                continue
            try:
                file_size = os.path.getsize(filepath)
                last_offset = state.get(filepath, 0)

                # File was truncated/rotated — start from beginning
                if file_size < last_offset:
                    last_offset = 0

                # No new data
                if file_size == last_offset:
                    continue

                with open(filepath, errors="replace") as f:
                    f.seek(last_offset)
                    for line in f:
                        line = line.rstrip()
                        if matches_patterns(line, patterns):
                            matches.append(f"[{filepath}] {line}")
                    state[filepath] = f.tell()
            except (PermissionError, OSError):
                continue
    return matches


def split_section(source, lines, max_len):
    """Split a source's lines into chunks that fit within max_len."""
    sections = []
    batch_start = 0
    batch_size = 20

    while batch_start < len(lines):
        batch = lines[batch_start : batch_start + batch_size]
        remaining = len(lines) - batch_start - len(batch)

        section = f"\n**{source}** ({len(lines)} matches"
        if batch_start > 0:
            section += f", from {batch_start + 1}"
        section += "):\n```\n"
        for line in batch:
            if len(line) > 200:
                line = line[:200] + "..."
            section += line + "\n"
        if remaining > 0:
            section += f"... and {remaining} more\n"
        section += "```\n"

        # If even a small batch is too big, force it through
        if len(section) > max_len and len(batch) > 1:
            batch_size = max(1, len(batch) // 2)
            continue

        sections.append(section)
        batch_start += len(batch)
        batch_size = 20

    return sections


def format_summary(hostname, source_results):
    """Format scan results into Discord message chunks."""
    total = sum(len(lines) for lines in source_results.values())
    if total == 0:
        return []

    chunks = []
    header = f"**[logscanner@{hostname}]** Found {total} error(s)\n"
    cont_header = f"**[logscanner@{hostname}]** (cont.)\n"
    # Reserve space for headers so sections don't exceed the limit
    section_max = MAX_DISCORD_LENGTH - len(cont_header)
    current = header

    for source, lines in source_results.items():
        if not lines:
            continue

        sections = split_section(source, lines, section_max)
        for section in sections:
            if len(current) + len(section) > MAX_DISCORD_LENGTH:
                if current.strip():
                    chunks.append(current)
                current = cont_header
            current += section

    if current.strip():
        chunks.append(current)

    return chunks


def send_discord(webhook_url, message):
    """Send a message to Discord webhook."""
    _send_discord(webhook_url, message, user_agent="logscanner/1.0")


@click.command()
@click.option("--config", required=True, help="Path to config JSON file.")
@click.option("--hours", type=int, default=24, help="Hours to look back.")
@click.option("--dry-run", is_flag=True, help="Print instead of sending.")
def main(config, hours, dry_run):
    """Scan system logs for errors and alert via Discord webhook."""
    cfg = load_config(config)
    hostname = platform.node()
    system = platform.system()
    results = {}

    # Compile patterns
    pattern_strings = cfg.get("patterns", DEFAULT_PATTERNS)
    compiled = [re.compile(p) for p in pattern_strings]

    # Scan system logs (only if enabled in config)
    scan_system = cfg.get("scanSystemLog", True)
    if scan_system:
        if system == "Darwin":
            predicate = cfg.get("darwinPredicate", "messageType == error")
            lines = scan_darwin_log(hours=hours, predicate=predicate)
            if lines:
                results["macOS unified log"] = lines
        elif system == "Linux":
            lines = scan_journalctl(hours=hours)
            if lines:
                results["systemd journal"] = lines

    # Scan file paths
    file_paths = cfg.get("logPaths", [])
    if file_paths:
        state_file = cfg.get("stateFile", "/tmp/logscanner-daemon-last-run")
        exclude = cfg.get("excludeFiles", ["logscanner."])
        state = load_state(state_file)
        file_matches = scan_files(file_paths, compiled, state, exclude=exclude)
        if file_matches:
            results["log files"] = file_matches
        save_state(state_file, state)

    # Format and send
    chunks = format_summary(hostname, results)

    if not chunks:
        print("No errors found.")
        return

    if dry_run:
        for chunk in chunks:
            print(chunk)
            print("---")
        return

    webhook_url = get_webhook_url(cfg)
    if not webhook_url:
        print("No Discord webhook configured, printing to stdout:")
        for chunk in chunks:
            print(chunk)
        return

    for chunk in chunks:
        send_discord(webhook_url, chunk)
        time.sleep(1)  # Rate limit

    print(f"Sent {len(chunks)} message(s) to Discord.")


if __name__ == "__main__":
    main(prog_name="logscanner")
