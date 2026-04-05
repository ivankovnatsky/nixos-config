"""Sync logic for *arr services (Radarr, Sonarr, Prowlarr)."""

import sys

from clients import ArrClient, ProwlarrClient


def _build_transmission_fields(config, category_field="movieCategory"):
    """Build the fields array for Transmission download client."""
    fields = [
        {"name": "host", "value": config.get("host", "localhost")},
        {"name": "port", "value": config.get("port", 9091)},
        {"name": "useSsl", "value": config.get("useSsl", False)},
        {"name": "urlBase", "value": config.get("urlBase", "/transmission/")},
        {"name": "username", "value": config["username"]},
        {"name": "password", "value": config["password"]},
        {"name": category_field, "value": config.get("category", "")},
        {"name": "addPaused", "value": config.get("addPaused", False)},
    ]
    return fields


def sync_radarr(config, dry_run=False):
    """Sync Radarr configuration."""
    client = ArrClient(config["baseUrl"], config["apiKey"])

    print("", file=sys.stderr)
    print("=== Radarr Sync ===", file=sys.stderr)

    # Sync host configuration (bind address, port, etc.)
    if "hostConfig" in config:
        print("", file=sys.stderr)
        print("Syncing host configuration...", file=sys.stderr)
        _sync_host_config(client, config["hostConfig"], dry_run)

    # Sync download clients
    if "downloadClients" in config:
        print("", file=sys.stderr)
        print("Syncing download clients...", file=sys.stderr)
        _sync_downloadclients(client, config["downloadClients"], "radarr", dry_run)

    # Sync root folders
    if "rootFolders" in config:
        print("", file=sys.stderr)
        print("Syncing root folders...", file=sys.stderr)
        _sync_rootfolders(client, config["rootFolders"], dry_run)

    print("", file=sys.stderr)
    print("Radarr sync complete!", file=sys.stderr)


def sync_sonarr(config, dry_run=False):
    """Sync Sonarr configuration."""
    client = ArrClient(config["baseUrl"], config["apiKey"])

    print("", file=sys.stderr)
    print("=== Sonarr Sync ===", file=sys.stderr)

    # Sync host configuration (bind address, port, etc.)
    if "hostConfig" in config:
        print("", file=sys.stderr)
        print("Syncing host configuration...", file=sys.stderr)
        _sync_host_config(client, config["hostConfig"], dry_run)

    # Sync download clients
    if "downloadClients" in config:
        print("", file=sys.stderr)
        print("Syncing download clients...", file=sys.stderr)
        _sync_downloadclients(client, config["downloadClients"], "sonarr", dry_run)

    # Sync root folders
    if "rootFolders" in config:
        print("", file=sys.stderr)
        print("Syncing root folders...", file=sys.stderr)
        _sync_rootfolders(client, config["rootFolders"], dry_run)

    print("", file=sys.stderr)
    print("Sonarr sync complete!", file=sys.stderr)


def sync_prowlarr(config, dry_run=False):
    """Sync Prowlarr configuration."""
    client = ProwlarrClient(config["baseUrl"], config["apiKey"])

    print("", file=sys.stderr)
    print("=== Prowlarr Sync ===", file=sys.stderr)

    # Sync host configuration (bind address, port, etc.)
    if "hostConfig" in config:
        print("", file=sys.stderr)
        print("Syncing host configuration...", file=sys.stderr)
        _sync_host_config(client, config["hostConfig"], dry_run)

    # Sync indexers
    if "indexers" in config:
        print("", file=sys.stderr)
        print("Syncing indexers...", file=sys.stderr)
        _sync_indexers(client, config["indexers"], dry_run)

    # Sync applications
    if "applications" in config:
        print("", file=sys.stderr)
        print("Syncing applications...", file=sys.stderr)
        _sync_applications(client, config["applications"], dry_run)

    print("", file=sys.stderr)
    print("Prowlarr sync complete!", file=sys.stderr)


def _sync_host_config(client, desired_config: dict, dry_run: bool):
    """Sync host configuration (bind address, port, etc.)."""
    current_config = client.get_host_config()

    # Check if update needed
    needs_update = False
    update_parts = []

    # Check bind address
    if "bindAddress" in desired_config:
        current_bind = current_config.get("bindAddress", "*")
        desired_bind = desired_config["bindAddress"]
        if current_bind != desired_bind:
            needs_update = True
            update_parts.append(f"bindAddress: {current_bind} -> {desired_bind}")

    if needs_update:
        print(f"  UPDATE: host config ({', '.join(update_parts)})", file=sys.stderr)
        if not dry_run:
            # Update only the fields we want to change, preserve rest
            update_data = current_config.copy()
            if "bindAddress" in desired_config:
                update_data["bindAddress"] = desired_config["bindAddress"]
            client.update_host_config(update_data)
    else:
        print("  OK: host config (no changes)", file=sys.stderr)


def _sync_downloadclients(
    client: ArrClient, desired_clients: list, service_type: str, dry_run: bool
):
    """Sync download clients for Radarr or Sonarr."""
    current_clients = {dc["name"]: dc for dc in client.list_downloadclients()}
    desired_clients_map = {dc["name"]: dc for dc in desired_clients}

    category_field = "movieCategory" if service_type == "radarr" else "tvCategory"

    for name, desired in desired_clients_map.items():
        if name in current_clients:
            current = current_clients[name]

            # Check if update needed
            needs_update = False
            update_parts = []

            # Build new fields
            new_fields = _build_transmission_fields(desired, category_field)

            # Compare fields (skip password comparison if masked)
            current_fields = {f["name"]: f for f in current.get("fields", [])}
            for field in new_fields:
                field_name = field["name"]
                if field_name == "password":
                    if desired["password"] != "********":
                        needs_update = True
                        update_parts.append("password")
                elif field_name in current_fields:
                    if field["value"] != current_fields[field_name].get("value"):
                        needs_update = True
                        update_parts.append(field_name)

            if needs_update:
                print(f"  UPDATE: {name} ({', '.join(update_parts)})", file=sys.stderr)
                if not dry_run:
                    # Build full update payload
                    update_data = current.copy()
                    update_data["fields"] = new_fields
                    client.update_downloadclient(current["id"], update_data)
            else:
                print(f"  OK: {name} (no changes)", file=sys.stderr)
        else:
            print(f"  CREATE: {name}", file=sys.stderr)
            if not dry_run:
                # Build create payload
                create_data = {
                    "enable": desired.get("enable", True),
                    "protocol": "torrent",
                    "priority": desired.get("priority", 1),
                    "removeCompletedDownloads": desired.get(
                        "removeCompletedDownloads", True
                    ),
                    "removeFailedDownloads": desired.get("removeFailedDownloads", True),
                    "name": name,
                    "fields": _build_transmission_fields(desired, category_field),
                    "implementationName": "Transmission",
                    "implementation": "Transmission",
                    "configContract": "TransmissionSettings",
                    "tags": [],
                }
                client.create_downloadclient(create_data)


def _sync_rootfolders(client: ArrClient, desired_folders: list, dry_run: bool):
    """Sync root folders (declarative - delete unmanaged, create missing)."""
    current_folders = {rf["path"]: rf for rf in client.list_rootfolders()}
    desired_folders_set = set(desired_folders)

    # Delete root folders not in desired config
    for path, current in current_folders.items():
        if path not in desired_folders_set:
            print(f"  DELETE: {path} (not in config)", file=sys.stderr)
            if not dry_run:
                client.delete_rootfolder(current["id"])

    # Create missing root folders
    for desired_path in desired_folders:
        if desired_path in current_folders:
            print(f"  OK: {desired_path} (already exists)", file=sys.stderr)
        else:
            print(f"  CREATE: {desired_path}", file=sys.stderr)
            if not dry_run:
                client.create_rootfolder(desired_path)


def _sync_applications(client: ProwlarrClient, desired_apps: list, dry_run: bool):
    """Sync Prowlarr applications."""
    current_apps = {app["name"]: app for app in client.list_applications()}
    desired_apps_map = {app["name"]: app for app in desired_apps}

    for name, desired in desired_apps_map.items():
        if name in current_apps:
            current = current_apps[name]

            # Check if update needed
            needs_update = False
            update_parts = []

            # Build fields
            new_fields = [
                {
                    "name": "prowlarrUrl",
                    "value": desired.get("prowlarrUrl", "http://localhost:9696"),
                },
                {"name": "baseUrl", "value": desired["baseUrl"]},
                {"name": "apiKey", "value": desired["apiKey"]},
                {"name": "syncCategories", "value": desired.get("syncCategories", [])},
            ]

            # Compare fields (skip apiKey if masked)
            current_fields = {f["name"]: f for f in current.get("fields", [])}
            for field in new_fields:
                field_name = field["name"]
                if field_name == "apiKey":
                    if desired["apiKey"] != "********":
                        needs_update = True
                        update_parts.append("apiKey")
                elif field_name in current_fields:
                    if field["value"] != current_fields[field_name].get("value"):
                        needs_update = True
                        update_parts.append(field_name)

            # Check syncLevel
            if desired.get("syncLevel") != current.get("syncLevel"):
                needs_update = True
                update_parts.append("syncLevel")

            if needs_update:
                print(f"  UPDATE: {name} ({', '.join(update_parts)})", file=sys.stderr)
                if not dry_run:
                    update_data = current.copy()
                    update_data["syncLevel"] = desired.get("syncLevel", "fullSync")
                    update_data["fields"] = new_fields
                    client.update_application(current["id"], update_data)
            else:
                print(f"  OK: {name} (no changes)", file=sys.stderr)
        else:
            print(f"  CREATE: {name}", file=sys.stderr)
            if not dry_run:
                # Determine implementation based on name
                implementation = "Radarr" if "radarr" in name.lower() else "Sonarr"
                create_data = {
                    "syncLevel": desired.get("syncLevel", "fullSync"),
                    "enable": desired.get("enable", True),
                    "name": name,
                    "fields": [
                        {
                            "name": "prowlarrUrl",
                            "value": desired.get(
                                "prowlarrUrl", "http://localhost:9696"
                            ),
                        },
                        {"name": "baseUrl", "value": desired["baseUrl"]},
                        {"name": "apiKey", "value": desired["apiKey"]},
                        {
                            "name": "syncCategories",
                            "value": desired.get("syncCategories", []),
                        },
                    ],
                    "implementationName": implementation,
                    "implementation": implementation,
                    "configContract": f"{implementation}Settings",
                    "tags": [],
                }
                client.create_application(create_data)


def _sync_indexers(client: ProwlarrClient, desired_indexers: list, dry_run: bool):
    """Sync Prowlarr indexers."""
    current_indexers = {idx["name"]: idx for idx in client.list_indexers()}
    desired_indexers_map = {idx["name"]: idx for idx in desired_indexers}

    # Delete indexers not in desired config
    for name, current in current_indexers.items():
        if name not in desired_indexers_map:
            print(f"  DELETE: {name} (not in config)", file=sys.stderr)
            if not dry_run:
                client.delete_indexer(current["id"])

    # Create or update indexers from desired config
    for name, desired in desired_indexers_map.items():
        if name in current_indexers:
            current = current_indexers[name]

            # Check if update needed
            needs_update = False
            update_parts = []

            # Check enable status
            if desired.get("enable", True) != current.get("enable"):
                needs_update = True
                update_parts.append(
                    f"enable: {current.get('enable')} -> {desired.get('enable', True)}"
                )

            # Check priority
            if desired.get("priority", 25) != current.get("priority"):
                needs_update = True
                update_parts.append(
                    f"priority: {current.get('priority')} -> {desired.get('priority', 25)}"
                )

            if needs_update:
                print(f"  UPDATE: {name} ({', '.join(update_parts)})", file=sys.stderr)
                if not dry_run:
                    update_data = current.copy()
                    update_data["enable"] = desired.get("enable", True)
                    update_data["priority"] = desired.get("priority", 25)
                    client.update_indexer(current["id"], update_data)
            else:
                print(f"  OK: {name} (no changes)", file=sys.stderr)
        else:
            # Create new indexer
            if "definitionName" not in desired:
                print(
                    f"  ERROR: {name} (missing definitionName - required for creation)",
                    file=sys.stderr,
                )
                continue

            print(
                f"  CREATE: {name} (definitionName: {desired['definitionName']})",
                file=sys.stderr,
            )
            if not dry_run:
                # Build create payload with implementation fields
                # Most public indexers use Cardigann (generic indexer framework)
                create_data = {
                    "definitionName": desired["definitionName"],
                    "name": name,
                    "enable": desired.get("enable", True),
                    "priority": desired.get("priority", 25),
                    "appProfileId": 1,  # Default app profile
                    "protocol": "torrent",
                    "implementationName": "Cardigann",
                    "implementation": "Cardigann",
                    "configContract": "CardigannSettings",
                    "fields": [
                        {"name": "definitionFile", "value": desired["definitionName"]}
                    ],
                }
                client.create_indexer(create_data)
