"""Battery: Report battery state (macOS + Linux)."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

import click

from common import is_linux, is_macos


def battery_get_macos() -> dict | None:
    """Read battery state on macOS via pmset -g batt.

    Returns dict with keys: percent (int), state (charging|discharging|charged|ac|unknown),
    time_remaining (str or None), source (AC Power|Battery Power|None), present (bool).
    Returns None if no internal battery is present (e.g. desktop Macs).
    """
    try:
        result = subprocess.run(
            ["pmset", "-g", "batt"],
            capture_output=True,
            text=True,
            check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None

    out = result.stdout
    if "InternalBattery" not in out:
        return None

    source_match = re.search(r"Now drawing from '([^']+)'", out)
    source = source_match.group(1) if source_match else None

    line_match = re.search(
        r"InternalBattery-\S+\s*(?:\(id=\d+\))?\s*(.+)$", out, re.MULTILINE
    )
    if not line_match:
        return None
    rest = line_match.group(1)

    percent_match = re.search(r"(\d+)%", rest)
    percent = int(percent_match.group(1)) if percent_match else None

    fields = [f.strip() for f in rest.split(";")]
    state = "unknown"
    for f in fields:
        f_lc = f.lower()
        if "discharging" in f_lc:
            state = "discharging"
            break
        if "not charging" in f_lc:
            state = "ac"
            break
        if "charging" in f_lc:
            state = "charging"
            break
        if "charged" in f_lc:
            state = "charged"
            break
        if "ac attached" in f_lc or f_lc == "finishing charge":
            state = "ac"
            break

    time_match = re.search(r"(\d+:\d{2})\s*remaining", rest)
    time_remaining = time_match.group(1) if time_match else None

    return {
        "percent": percent,
        "state": state,
        "time_remaining": time_remaining,
        "source": source,
        "present": True,
    }


def battery_get_linux() -> dict | None:
    """Read battery state on Linux via /sys/class/power_supply/BAT*."""
    base = Path("/sys/class/power_supply")
    if not base.is_dir():
        return None

    bats = sorted(p for p in base.iterdir() if p.name.startswith("BAT"))
    if not bats:
        return None
    bat = bats[0]

    def read(name: str) -> str | None:
        p = bat / name
        if not p.is_file():
            return None
        try:
            return p.read_text().strip()
        except OSError:
            return None

    capacity = read("capacity")
    status = (read("status") or "Unknown").lower()
    state_map = {
        "charging": "charging",
        "discharging": "discharging",
        "full": "charged",
        "not charging": "ac",
    }
    state = state_map.get(status, "unknown")

    ac_online = None
    for ac in base.iterdir():
        if not ac.name.startswith(("AC", "ADP", "ACAD")):
            continue
        online_path = ac / "online"
        if not online_path.is_file():
            continue
        online = online_path.read_text().strip()
        if online == "1":
            ac_online = True
            break
        if ac_online is None:
            ac_online = False

    source = (
        "AC Power" if ac_online else ("Battery Power" if ac_online is False else None)
    )

    return {
        "percent": int(capacity) if capacity and capacity.isdigit() else None,
        "state": state,
        "time_remaining": None,
        "source": source,
        "present": True,
    }


def battery_get() -> dict | None:
    """Get current battery state, or None if no battery is present."""
    if is_macos():
        return battery_get_macos()
    if is_linux():
        return battery_get_linux()
    return None


def format_human(info: dict) -> str:
    parts = []
    if info.get("percent") is not None:
        parts.append(f"{info['percent']}%")
    state = info.get("state")
    if state and state != "unknown":
        parts.append(state)
    if info.get("time_remaining"):
        parts.append(f"{info['time_remaining']} remaining")
    if info.get("source"):
        parts.append(f"on {info['source']}")
    return ", ".join(parts) if parts else "unknown"


def register(cli):
    @cli.command()
    @click.option("--json", "as_json", is_flag=True, help="Output as JSON")
    def battery(as_json):
        """Show battery state (macOS + Linux)"""
        if not is_macos() and not is_linux():
            print("Battery info only available on macOS and Linux", file=sys.stderr)
            sys.exit(1)

        info = battery_get()
        if as_json:
            print(json.dumps(info))
            return

        if info is None:
            print("No battery detected", file=sys.stderr)
            sys.exit(1)

        print(f"Battery: {format_human(info)}")
