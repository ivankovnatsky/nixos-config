"""Declarative sync logic for Jellyfin libraries and network configuration."""

import sys

from client import JellyfinClient


def sync_from_config(config, dry_run=False):
    """
    Sync libraries and network configuration.
    Creates missing items, updates existing ones.
    """
    client = JellyfinClient(config["baseUrl"], config["apiKey"])

    # Sync network configuration (bind address)
    if "networkConfig" in config:
        _sync_network_config(client, config["networkConfig"], dry_run)

    # Sync libraries
    if "libraries" in config:
        _sync_libraries(client, config["libraries"], dry_run)


def _sync_network_config(client: JellyfinClient, network_config: dict, dry_run: bool):
    """Sync network configuration (bind addresses)."""
    current = client.get_network_config()
    desired_addresses = network_config.get("localNetworkAddresses", [])
    current_addresses = current.get("LocalNetworkAddresses", [])

    print("", file=sys.stderr)
    print("=== Network Configuration Sync ===", file=sys.stderr)

    if set(current_addresses) != set(desired_addresses):
        print("  UPDATE: LocalNetworkAddresses", file=sys.stderr)
        print(f"    Current: {current_addresses}", file=sys.stderr)
        print(f"    Desired: {desired_addresses}", file=sys.stderr)
        if not dry_run:
            try:
                result = client.update_network_config(desired_addresses)
                print(f"  DEBUG: API call result: {result}", file=sys.stderr)
                print(
                    "  NOTE: Jellyfin service must be restarted for changes to take effect",
                    file=sys.stderr,
                )
            except Exception as e:
                print(f"  ERROR: Failed to update network config: {e}", file=sys.stderr)
                raise
    else:
        print("  OK: LocalNetworkAddresses (no changes)", file=sys.stderr)


def _sync_libraries(
    client: JellyfinClient, libraries_config: list, dry_run: bool = False
):
    """Sync libraries from configuration."""
    desired_libraries = {lib["name"]: lib for lib in libraries_config}
    current_libraries = {lib["Name"]: lib for lib in client.list_libraries()}

    print("", file=sys.stderr)
    print("=== Library Sync ===", file=sys.stderr)
    print(f"  Desired libraries: {len(desired_libraries)}", file=sys.stderr)
    print(f"  Current libraries: {len(current_libraries)}", file=sys.stderr)

    if dry_run:
        print("", file=sys.stderr)
        print("Dry-run mode - no changes will be made", file=sys.stderr)
        print("", file=sys.stderr)

    # Create or update libraries
    for name, desired in desired_libraries.items():
        paths = desired["paths"]
        library_type = desired.get("type", "movies")

        if name in current_libraries:
            current = current_libraries[name]

            # Check if paths need update
            current_paths_list = current.get("Locations", [])
            current_paths = set(current_paths_list)
            desired_paths = set(paths)
            paths_changed = current_paths != desired_paths

            if paths_changed:
                print(
                    f"  UPDATE: {name} (paths: {current_paths} -> {desired_paths})",
                    file=sys.stderr,
                )
                if not dry_run:
                    client.update_library_paths(name, current_paths_list, paths)
            else:
                print(f"  OK: {name} (no changes)", file=sys.stderr)
        else:
            print(f"  CREATE: {name} (type: {library_type})", file=sys.stderr)
            if not dry_run:
                client.create_library(
                    name=name, paths=paths, collection_type=library_type
                )

    # Sync library options (after all libraries are created/updated)
    if "libraryOptions" in desired or any(
        "libraryOptions" in lib for lib in desired_libraries.values()
    ):
        print("", file=sys.stderr)
        print("=== Library Options Sync ===", file=sys.stderr)
        for name, desired in desired_libraries.items():
            desired_lib_options = desired.get("libraryOptions", {})
            if not desired_lib_options:
                continue

            library_id = client.get_library_id(name)
            if not library_id:
                print(
                    f"  WARNING: Could not find library ID for {name}", file=sys.stderr
                )
                continue

            current_lib_options = client.get_library_options(library_id)

            # Check if library options need update
            options_changed = False
            changes = []

            if "enableRealtimeMonitor" in desired_lib_options:
                desired_monitor = desired_lib_options["enableRealtimeMonitor"]
                current_monitor = current_lib_options.get(
                    "EnableRealtimeMonitor", False
                )
                if desired_monitor != current_monitor:
                    options_changed = True
                    changes.append(
                        f"EnableRealtimeMonitor: {current_monitor} -> {desired_monitor}"
                    )

            if "automaticRefreshIntervalDays" in desired_lib_options:
                desired_interval = desired_lib_options["automaticRefreshIntervalDays"]
                current_interval = current_lib_options.get(
                    "AutomaticRefreshIntervalDays", 0
                )
                if desired_interval != current_interval:
                    options_changed = True
                    changes.append(
                        f"AutomaticRefreshIntervalDays: {current_interval} -> {desired_interval}"
                    )

            if options_changed:
                print(f"  UPDATE: {name} library options", file=sys.stderr)
                for change in changes:
                    print(f"    {change}", file=sys.stderr)
                if not dry_run:
                    # Merge desired options into current options
                    updated_options = current_lib_options.copy()
                    if "enableRealtimeMonitor" in desired_lib_options:
                        updated_options["EnableRealtimeMonitor"] = desired_lib_options[
                            "enableRealtimeMonitor"
                        ]
                    if "automaticRefreshIntervalDays" in desired_lib_options:
                        updated_options["AutomaticRefreshIntervalDays"] = (
                            desired_lib_options["automaticRefreshIntervalDays"]
                        )

                    client.update_library_options(library_id, updated_options)
            else:
                print(f"  OK: {name} library options (no changes)", file=sys.stderr)

    if dry_run:
        print("", file=sys.stderr)
        print("Library sync dry-run complete - no changes made.", file=sys.stderr)
    else:
        print("", file=sys.stderr)
        print("Library sync complete!", file=sys.stderr)
