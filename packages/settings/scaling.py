"""Scaling: Display Resolution (macOS only)."""

from __future__ import annotations

import os
import re
import subprocess
import sys

import click

from common import DISPLAYPLACER_PATH, is_macos
from dock import dock_toggle

SCALING_MODEL_RESOLUTIONS = {
    "Mac14,2": ("1470x956", "1280x832"),  # MacBook Air 13" M2
    "Mac15,7": ("1728x1117", "1496x967"),  # MacBook Pro 16" M3
    "MacBookPro18,1": ("1728x1117", "1496x967"),  # MacBook Pro 16" M1 Pro/Max
}


def scaling_get_model_identifier() -> str:
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


def scaling_get_displayplacer_output() -> str:
    """Get raw output from displayplacer list."""
    if not os.path.exists(DISPLAYPLACER_PATH):
        return ""
    try:
        result = subprocess.run(
            [DISPLAYPLACER_PATH, "list"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error running displayplacer: {e}", file=sys.stderr)
        return ""


def scaling_parse_displays() -> list[dict]:
    """Parse displayplacer list output into a list of display info dicts."""
    output = scaling_get_displayplacer_output()
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


def scaling_get_builtin_display() -> dict | None:
    """Get the built-in MacBook display info."""
    displays = scaling_parse_displays()
    for display in displays:
        if display.get("type") == "MacBook built in screen":
            return display
    return None


def scaling_get_scaled_modes(display: dict) -> list[dict]:
    """Get all modes with scaling enabled, sorted by resolution (largest first)."""
    modes = [m for m in display.get("modes", []) if m.get("scaling")]
    modes.sort(key=lambda m: scaling_parse_resolution(m["res"]), reverse=True)
    return modes


def scaling_parse_resolution(res: str) -> int:
    """Parse resolution string to pixel count for sorting."""
    try:
        w, h = res.split("x")
        return int(w) * int(h)
    except (ValueError, AttributeError):
        return 0


def scaling_find_mode_by_resolution(display: dict, resolution: str) -> dict | None:
    """Find a mode by resolution string."""
    for mode in display.get("modes", []):
        if mode.get("res") == resolution:
            return mode
    return None


def scaling_get_resolution_pair(display: dict) -> tuple[dict | None, dict | None]:
    """Get default (more space) and scaled (larger text) mode pair."""
    model = scaling_get_model_identifier()
    if model in SCALING_MODEL_RESOLUTIONS:
        default_res, scaled_res = SCALING_MODEL_RESOLUTIONS[model]
        default_mode = scaling_find_mode_by_resolution(display, default_res)
        scaled_mode = scaling_find_mode_by_resolution(display, scaled_res)
        if default_mode and scaled_mode:
            return default_mode, scaled_mode

    modes = scaling_get_scaled_modes(display)
    if len(modes) < 2:
        return None, None
    return modes[0], modes[1]


def scaling_get_current_display_args() -> list[str]:
    """Build displayplacer args for all displays with their current settings."""
    output = scaling_get_displayplacer_output()
    if not output:
        return []

    match = re.search(r'displayplacer\s+"([^"]+)"', output)
    if not match:
        match = re.findall(r'"(id:\S+[^"]*)"', output)
        if match:
            return list(match)
        return []

    args = [match.group(1)]
    for extra in re.findall(r'"(id:\S+[^"]*)"', output[match.end() :]):
        args.append(extra)
    return args


def scaling_set_resolution(display: dict, mode: dict) -> bool:
    """Set display resolution using displayplacer."""
    if not os.path.exists(DISPLAYPLACER_PATH):
        print("displayplacer not found", file=sys.stderr)
        return False

    screen_id = display.get("id")
    if not screen_id:
        print("Could not determine screen ID", file=sys.stderr)
        return False

    target_arg = f"id:{screen_id} res:{mode['res']} hz:{mode['hz']} color_depth:{mode['color_depth']} scaling:on"

    current_args = scaling_get_current_display_args()
    cmd = [DISPLAYPLACER_PATH]
    replaced = False
    for arg in current_args:
        if f"id:{screen_id}" in arg:
            cmd.append(target_arg)
            replaced = True
        else:
            cmd.append(arg)
    if not replaced:
        cmd.append(target_arg)

    try:
        subprocess.run(cmd, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error setting resolution: {e}", file=sys.stderr)
        return False


def scaling_get_current_mode_name(display: dict) -> str | None:
    """Get the current scaling mode name: 'scaled', 'default', or None."""
    current = display.get("resolution")
    if not current:
        return None

    default_mode, scaled_mode = scaling_get_resolution_pair(display)
    if not default_mode or not scaled_mode:
        return None

    if current == scaled_mode["res"]:
        return "scaled"
    elif current == default_mode["res"]:
        return "default"
    else:
        return None


def scaling_set_mode(mode: str) -> int:
    """Set display to specific scaling mode ('scaled' or 'default')."""
    display = scaling_get_builtin_display()
    if not display:
        print("Could not find built-in display", file=sys.stderr)
        return 1

    default_mode, scaled_mode = scaling_get_resolution_pair(display)
    if not default_mode or not scaled_mode:
        print("Could not find suitable resolution modes", file=sys.stderr)
        return 1

    current = display.get("resolution")

    if mode == "scaled":
        target_mode = scaled_mode
        label = "larger text"
    else:
        target_mode = default_mode
        label = "more space"

    if current == target_mode["res"]:
        print(f"Already at {label} ({target_mode['res']})")
        return 0

    if scaling_set_resolution(display, target_mode):
        print(f"Switched to {label} ({target_mode['res']})")
        return 0

    return 1


def scaling_toggle() -> int:
    """Toggle display scaling."""
    display = scaling_get_builtin_display()
    if not display:
        print("Could not find built-in display", file=sys.stderr)
        return 1

    current = display.get("resolution")
    if not current:
        print("Could not determine current resolution", file=sys.stderr)
        return 1

    default_mode, scaled_mode = scaling_get_resolution_pair(display)
    if not default_mode or not scaled_mode:
        print("Could not find suitable resolution modes", file=sys.stderr)
        return 1

    if current == default_mode["res"]:
        if scaling_set_resolution(display, scaled_mode):
            print(f"Switched to larger text ({scaled_mode['res']})")
            return 0
    else:
        if scaling_set_resolution(display, default_mode):
            print(f"Switched to more space ({default_mode['res']})")
            return 0

    return 1


def register(cli):
    @cli.command()
    @click.option("--status", is_flag=True, help="Show current scaling mode")
    @click.option(
        "--init",
        is_flag=True,
        help="Initialize to scaled mode (idempotent, for activation scripts)",
    )
    @click.option(
        "--mode",
        type=click.Choice(["scaled", "default"]),
        help="Set specific mode: 'scaled' (larger text) or 'default' (more space)",
    )
    @click.option(
        "--dock", "also_dock", is_flag=True, help="Also toggle dock auto-hide"
    )
    def scaling(status, init, mode, also_dock):
        """Toggle display scaling (macOS only)"""
        if not is_macos():
            print("Scaling settings only available on macOS", file=sys.stderr)
            sys.exit(1)

        if init:
            display = scaling_get_builtin_display()
            if not display:
                print("Skipping scaling init (no built-in display)")
                return
            mode_name = scaling_get_current_mode_name(display)
            if mode_name == "scaled":
                print("Skipping scaling init (already at scaled)")
                return
            result = scaling_set_mode("scaled")
            if result == 0:
                print("Initialized scaling to larger text")
            if result != 0:
                sys.exit(result)
            return

        if status:
            display = scaling_get_builtin_display()
            if not display:
                print("Could not find built-in display", file=sys.stderr)
                sys.exit(1)
            current = display.get("resolution")
            mode_name = scaling_get_current_mode_name(display)
            default_mode, scaled_mode = scaling_get_resolution_pair(display)
            if mode_name == "scaled":
                print(f"Scaling: larger text ({current})")
            elif mode_name == "default":
                print(f"Scaling: more space ({current})")
            else:
                print(f"Scaling: custom ({current})")
                if default_mode and scaled_mode:
                    print(
                        f"  Available: more space ({default_mode['res']}), larger text ({scaled_mode['res']})"
                    )
            return

        if mode:
            result = scaling_set_mode(mode)
        else:
            result = scaling_toggle()

        if result == 0 and also_dock:
            dock_toggle()
        if result != 0:
            sys.exit(result)
