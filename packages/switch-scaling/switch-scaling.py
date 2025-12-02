#!/usr/bin/env python3
"""Toggle display scaling between default and scaled (larger text) modes."""

import subprocess
import sys

# MacBook Pro 14" built-in display resolutions
DEFAULT_RES = "1728x1117"  # Default scaling
SCALED_RES = "1496x967"    # Larger text (for laptop on stand)
HZ = "120"
COLOR_DEPTH = "8"


def parse_displays() -> list[dict]:
    """Parse displayplacer list output into a list of display info dicts."""
    try:
        result = subprocess.run(
            ["displayplacer", "list"],
            capture_output=True,
            text=True,
            check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error running displayplacer: {e}", file=sys.stderr)
        return []

    displays = []
    current_display = {}

    for line in result.stdout.splitlines():
        if line.startswith("Persistent screen id:"):
            if current_display:
                displays.append(current_display)
            current_display = {"id": line.split(":", 1)[1].strip()}
        elif line.startswith("Type:"):
            current_display["type"] = line.split(":", 1)[1].strip()
        elif line.startswith("Resolution:"):
            current_display["resolution"] = line.split(":", 1)[1].strip()
        elif "<-- current mode" in line:
            # Extract resolution from mode line
            parts = line.split()
            for part in parts:
                if part.startswith("res:"):
                    current_display["resolution"] = part.replace("res:", "")

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


def get_current_resolution() -> str | None:
    """Get current resolution of the built-in display."""
    display = get_builtin_display()
    if display:
        return display.get("resolution")
    return None


def get_screen_id() -> str | None:
    """Get the persistent screen ID for the built-in display."""
    display = get_builtin_display()
    if display:
        return display.get("id")
    return None


def set_resolution(resolution: str) -> bool:
    """Set display resolution using displayplacer."""
    screen_id = get_screen_id()
    if not screen_id:
        print("Could not determine screen ID", file=sys.stderr)
        return False

    cmd = [
        "displayplacer",
        f"id:{screen_id} res:{resolution} hz:{HZ} color_depth:{COLOR_DEPTH} scaling:on",
    ]

    try:
        subprocess.run(cmd, check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error setting resolution: {e}", file=sys.stderr)
        return False


def main() -> int:
    current = get_current_resolution()
    if not current:
        print("Could not determine current resolution", file=sys.stderr)
        return 1

    if current == DEFAULT_RES:
        # Switch to scaled (larger text)
        if set_resolution(SCALED_RES):
            print(f"Switched to scaled mode ({SCALED_RES}) - larger text")
            return 0
    else:
        # Switch to default
        if set_resolution(DEFAULT_RES):
            print(f"Switched to default mode ({DEFAULT_RES})")
            return 0

    return 1


if __name__ == "__main__":
    sys.exit(main())
