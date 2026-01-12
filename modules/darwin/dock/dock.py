#!/usr/bin/env python3
"""
Manage macOS Dock configuration.
Compares current dock state with desired state and rebuilds if needed.
"""

import sys
import subprocess
import json
import urllib.parse


def normalize_path_to_uri(path: str) -> str:
    """
    Convert a filesystem path to a file:// URI.
    - Adds trailing slash to .app bundles (whether it's there or not)
    - Properly URL-encodes special characters
    """
    path = path.strip()

    # Always add trailing slash to .app bundles if not present
    if path.endswith(".app") or path.endswith(".app/"):
        path = path.rstrip("/") + "/"

    # Convert to file:// URI with proper encoding
    encoded = urllib.parse.quote(path, safe="/:")
    return f"file://{encoded}"


def normalize_uri_list(uris: str) -> list[str]:
    """
    Normalize a newline-separated list of paths/URIs.
    Handles both raw paths (from dockutil) and file:// URIs (from config).
    """
    result = []
    for line in uris.strip().split("\n"):
        line = line.strip()
        if not line:
            result.append("")  # Preserve empty lines (spacers)
            continue

        # If it's already a file:// URI, parse it back to path first
        if line.startswith("file://"):
            parsed = urllib.parse.urlparse(line)
            path = urllib.parse.unquote(parsed.path)
        else:
            path = line

        # Normalize to URI
        result.append(normalize_path_to_uri(path))

    return result


def compare_dock_configs(have: str, want: str) -> bool:
    """
    Compare two dock configurations.
    Returns True if same, False if different.
    """
    have_uris = normalize_uri_list(have)
    want_uris = normalize_uri_list(want)
    return have_uris == want_uris


def run_command(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess:
    """Run a shell command and return the result."""
    try:
        return subprocess.run(cmd, check=check, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running {' '.join(cmd)}: {e.stderr}", file=sys.stderr)
        raise


def rebuild_dock(dockutil_path: str, entries_json: str) -> None:
    """
    Rebuild dock from scratch.
    entries_json is a JSON array of dock entry objects.
    """
    entries = json.loads(entries_json)

    # Remove all existing items
    print("Resetting Dock.", file=sys.stderr)
    run_command([dockutil_path, "--no-restart", "--remove", "all"])

    # Add all desired items
    for entry in entries:
        entry_type = entry.get("type", "")

        if entry_type == "spacer":
            # Add spacer
            section = entry.get("section", "apps")
            cmd = [
                dockutil_path,
                "--no-restart",
                "--add",
                "",
                "--type",
                "spacer",
                "--section",
                section,
            ]
            run_command(cmd, check=False)
        else:
            # Add regular item
            path = entry["path"].rstrip("/")  # Remove trailing slash for dockutil
            section = entry.get("section", "apps")
            options = entry.get("options", "").strip()

            cmd = [dockutil_path, "--no-restart", "--add", path, "--section", section]

            # Add additional options if present
            if options:
                # Parse options string into individual arguments
                cmd.extend(options.split())

            print(f"adding {path}", file=sys.stderr)
            run_command(cmd, check=False)

    print("Dock setup complete.", file=sys.stderr)


def get_current_dock(dockutil_path: str) -> str:
    """Get current dock items using dockutil."""
    result = run_command([dockutil_path, "--list"])
    # Extract just the paths (second column)
    lines = result.stdout.strip().split("\n")
    paths = []
    for line in lines:
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) >= 2:
            paths.append(parts[1])
    return "\n".join(paths)


def entries_to_uris(entries: list) -> str:
    """Convert entries list to URI string format for comparison."""
    uris = []
    for entry in entries:
        if entry.get("type") == "spacer":
            uris.append("")
        else:
            path = entry["path"]
            # Normalize path to URI
            if path.endswith(".app") or path.endswith(".app/"):
                path = path.rstrip("/") + "/"
            # URL encode and add file:// prefix
            encoded = urllib.parse.quote(path, safe="/:")
            uris.append(f"file://{encoded}")
    return "\n".join(uris)


def main():
    """
    CLI interface for dock management.
    Usage: dock.py <dockutil_path> <entries_json>

    Exit codes:
    0 - Success (dock is up to date or was rebuilt)
    1 - Error
    """
    if len(sys.argv) != 3:
        print("Usage: dock.py <dockutil_path> <entries_json>", file=sys.stderr)
        sys.exit(1)

    dockutil_path = sys.argv[1]
    entries_json = sys.argv[2]

    # Parse entries
    try:
        entries = json.loads(entries_json)
    except json.JSONDecodeError as e:
        print(f"Error parsing entries JSON: {e}", file=sys.stderr)
        sys.exit(1)

    # Get current dock state
    current = get_current_dock(dockutil_path)
    wanted = entries_to_uris(entries)

    # Compare current vs wanted
    if compare_dock_configs(current, wanted):
        print("Dock is already up to date.", file=sys.stderr)
        sys.exit(0)

    # Dock needs updating - rebuild it
    rebuild_dock(dockutil_path, entries_json)
    sys.exit(0)


if __name__ == "__main__":
    main()
