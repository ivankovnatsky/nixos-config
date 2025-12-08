#!/usr/bin/env python3
"""Toggle display scaling between default and scaled (larger text) modes."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from typing import Optional

# Model-specific resolution mappings: model_id -> (default_res, scaled_res)
# Default = more space, Scaled = larger text
MODEL_RESOLUTIONS = {
    "Mac14,2": ("1470x956", "1280x832"),  # MacBook Air 13" M2
    "Mac15,7": ("1728x1117", "1496x967"),  # MacBook Pro 16" M3
}


def get_model_identifier() -> str:
    """Get the Mac model identifier."""
    try:
        result = subprocess.run(
            ["sysctl", "-n", "hw.model"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def get_displayplacer_output() -> str:
    """Get raw output from displayplacer list."""
    try:
        result = subprocess.run(
            ["displayplacer", "list"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error running displayplacer: {e}", file=sys.stderr)
        return ""


def parse_displays() -> list[dict]:
    """Parse displayplacer list output into a list of display info dicts."""
    output = get_displayplacer_output()
    if not output:
        return []

    displays = []
    current_display = {}

    for line in output.splitlines():
        if line.startswith("Persistent screen id:"):
            if current_display:
                displays.append(current_display)
            current_display = {"id": line.split(":", 1)[1].strip(), "modes": []}
        elif line.startswith("Type:"):
            current_display["type"] = line.split(":", 1)[1].strip()
        elif line.startswith("Hertz:"):
            current_display["hz"] = line.split(":", 1)[1].strip()
        elif line.startswith("Color Depth:"):
            current_display["color_depth"] = line.split(":", 1)[1].strip()
        elif line.startswith("Resolution:"):
            current_display["resolution"] = line.split(":", 1)[1].strip()
        elif line.strip().startswith("mode "):
            # Parse mode line: "  mode 6: res:1470x956 hz:60 color_depth:8 scaling:on"
            mode_match = re.search(
                r"res:(\S+)\s+hz:(\d+)\s+color_depth:(\d+)(?:\s+scaling:(\w+))?",
                line,
            )
            if mode_match:
                mode = {
                    "res": mode_match.group(1),
                    "hz": mode_match.group(2),
                    "color_depth": mode_match.group(3),
                    "scaling": mode_match.group(4) == "on",
                    "current": "<-- current mode" in line,
                }
                current_display.setdefault("modes", []).append(mode)
                if mode["current"]:
                    current_display["resolution"] = mode["res"]
                    current_display["hz"] = mode["hz"]
                    current_display["color_depth"] = mode["color_depth"]

    if current_display:
        displays.append(current_display)

    return displays


def get_builtin_display() -> dict | None:
    """Get the built-in MacBook display info."""
    displays = parse_displays()
    for display in displays:
        if display.get("type") == "MacBook built in screen":
            return display
    return None


def get_scaled_modes(display: dict) -> list[dict]:
    """Get all modes with scaling enabled, sorted by resolution (largest first)."""
    modes = [m for m in display.get("modes", []) if m.get("scaling")]
    # Sort by pixel count (width * height), largest first
    modes.sort(key=lambda m: parse_resolution(m["res"]), reverse=True)
    return modes


def parse_resolution(res: str) -> int:
    """Parse resolution string to pixel count for sorting."""
    try:
        w, h = res.split("x")
        return int(w) * int(h)
    except (ValueError, AttributeError):
        return 0


def find_mode_by_resolution(display: dict, resolution: str) -> dict | None:
    """Find a mode by resolution string."""
    for mode in display.get("modes", []):
        if mode.get("res") == resolution:
            return mode
    return None


def get_resolution_pair(display: dict) -> tuple[dict | None, dict | None]:
    """Get default (more space) and scaled (larger text) mode pair.

    First checks for model-specific mappings, then falls back to auto-detect
    (two largest scaled modes).
    """
    # Check for model-specific mapping
    model = get_model_identifier()
    if model in MODEL_RESOLUTIONS:
        default_res, scaled_res = MODEL_RESOLUTIONS[model]
        default_mode = find_mode_by_resolution(display, default_res)
        scaled_mode = find_mode_by_resolution(display, scaled_res)
        if default_mode and scaled_mode:
            return default_mode, scaled_mode

    # Fallback: auto-detect two largest scaled modes
    modes = get_scaled_modes(display)
    if len(modes) < 2:
        return None, None
    return modes[0], modes[1]


def set_resolution(display: dict, mode: dict) -> bool:
    """Set display resolution using displayplacer."""
    screen_id = display.get("id")
    if not screen_id:
        print("Could not determine screen ID", file=sys.stderr)
        return False

    cmd = [
        "displayplacer",
        f"id:{screen_id} res:{mode['res']} hz:{mode['hz']} color_depth:{mode['color_depth']} scaling:on",
    ]

    try:
        subprocess.run(cmd, check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error setting resolution: {e}", file=sys.stderr)
        return False


def get_dock_autohide() -> bool:
    """Check if dock autohide is enabled."""
    try:
        result = subprocess.run(
            ["defaults", "read", "com.apple.dock", "autohide"],
            capture_output=True,
            text=True,
        )
        return result.stdout.strip() == "1"
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def set_dock_autohide(enabled: bool) -> bool:
    """Set dock autohide and restart dock."""
    try:
        subprocess.run(
            ["defaults", "write", "com.apple.dock", "autohide", "-bool", str(enabled).lower()],
            check=True,
        )
        subprocess.run(["killall", "Dock"], check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error setting dock autohide: {e}", file=sys.stderr)
        return False


def toggle_dock() -> int:
    """Toggle dock visibility."""
    current = get_dock_autohide()
    if set_dock_autohide(not current):
        status = "hidden" if not current else "visible"
        print(f"Dock is now {status}")
        return 0
    return 1


def toggle_scaling() -> int:
    """Toggle display scaling."""
    display = get_builtin_display()
    if not display:
        print("Could not find built-in display", file=sys.stderr)
        return 1

    current = display.get("resolution")
    if not current:
        print("Could not determine current resolution", file=sys.stderr)
        return 1

    default_mode, scaled_mode = get_resolution_pair(display)
    if not default_mode or not scaled_mode:
        print("Could not find suitable resolution modes", file=sys.stderr)
        return 1

    if current == default_mode["res"]:
        # Switch to scaled (larger text)
        if set_resolution(display, scaled_mode):
            print(f"Switched to larger text ({scaled_mode['res']})")
            return 0
    else:
        # Switch to default (more space)
        if set_resolution(display, default_mode):
            print(f"Switched to more space ({default_mode['res']})")
            return 0

    return 1


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Toggle display scaling and dock visibility on macOS. "
        "Switches between 'more space' and 'larger text' display modes, "
        "and toggles dock auto-hide accordingly."
    )
    parser.parse_args()

    result = toggle_scaling()
    if result == 0:
        toggle_dock()
    return result


if __name__ == "__main__":
    sys.exit(main())
