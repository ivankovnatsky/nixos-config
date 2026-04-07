"""Sync logic for *arr services (Radarr, Sonarr, Lidarr, Prowlarr)."""

import click

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

    click.echo("", err=True)
    click.echo("=== Radarr Sync ===", err=True)

    # Sync host configuration (bind address, port, etc.)
    if "hostConfig" in config:
        click.echo("", err=True)
        click.echo("Syncing host configuration...", err=True)
        _sync_host_config(client, config["hostConfig"], dry_run)

    # Sync download clients
    if "downloadClients" in config:
        click.echo("", err=True)
        click.echo("Syncing download clients...", err=True)
        _sync_downloadclients(client, config["downloadClients"], "radarr", dry_run)

    # Sync root folders
    if "rootFolders" in config:
        click.echo("", err=True)
        click.echo("Syncing root folders...", err=True)
        _sync_rootfolders(client, config["rootFolders"], dry_run)

    click.echo("", err=True)
    click.echo("Radarr sync complete!", err=True)


def sync_lidarr(config, dry_run=False):
    """Sync Lidarr configuration."""
    client = ArrClient(config["baseUrl"], config["apiKey"], api_version=1)

    click.echo("", err=True)
    click.echo("=== Lidarr Sync ===", err=True)

    # Sync host configuration (bind address, port, etc.)
    if "hostConfig" in config:
        click.echo("", err=True)
        click.echo("Syncing host configuration...", err=True)
        _sync_host_config(client, config["hostConfig"], dry_run)

    # Sync download clients
    if "downloadClients" in config:
        click.echo("", err=True)
        click.echo("Syncing download clients...", err=True)
        _sync_downloadclients(client, config["downloadClients"], "lidarr", dry_run)

    # Sync root folders (Lidarr requires name + profile IDs)
    if "rootFolders" in config:
        click.echo("", err=True)
        click.echo("Syncing root folders...", err=True)
        quality_profiles = client.list_qualityprofiles()
        metadata_profiles = client.list_metadataprofiles()
        extra_kwargs = {}
        if quality_profiles:
            extra_kwargs["defaultQualityProfileId"] = quality_profiles[0]["id"]
        if metadata_profiles:
            extra_kwargs["defaultMetadataProfileId"] = metadata_profiles[0]["id"]
        _sync_rootfolders(client, config["rootFolders"], dry_run, **extra_kwargs)

    click.echo("", err=True)
    click.echo("Lidarr sync complete!", err=True)


def sync_sonarr(config, dry_run=False):
    """Sync Sonarr configuration."""
    client = ArrClient(config["baseUrl"], config["apiKey"])

    click.echo("", err=True)
    click.echo("=== Sonarr Sync ===", err=True)

    # Sync host configuration (bind address, port, etc.)
    if "hostConfig" in config:
        click.echo("", err=True)
        click.echo("Syncing host configuration...", err=True)
        _sync_host_config(client, config["hostConfig"], dry_run)

    # Sync download clients
    if "downloadClients" in config:
        click.echo("", err=True)
        click.echo("Syncing download clients...", err=True)
        _sync_downloadclients(client, config["downloadClients"], "sonarr", dry_run)

    # Sync root folders
    if "rootFolders" in config:
        click.echo("", err=True)
        click.echo("Syncing root folders...", err=True)
        _sync_rootfolders(client, config["rootFolders"], dry_run)

    click.echo("", err=True)
    click.echo("Sonarr sync complete!", err=True)


def sync_prowlarr(config, dry_run=False):
    """Sync Prowlarr configuration."""
    client = ProwlarrClient(config["baseUrl"], config["apiKey"])

    click.echo("", err=True)
    click.echo("=== Prowlarr Sync ===", err=True)

    # Sync host configuration (bind address, port, etc.)
    if "hostConfig" in config:
        click.echo("", err=True)
        click.echo("Syncing host configuration...", err=True)
        _sync_host_config(client, config["hostConfig"], dry_run)

    # Sync indexers
    if "indexers" in config:
        click.echo("", err=True)
        click.echo("Syncing indexers...", err=True)
        _sync_indexers(client, config["indexers"], dry_run)

    # Sync applications
    if "applications" in config:
        click.echo("", err=True)
        click.echo("Syncing applications...", err=True)
        _sync_applications(client, config["applications"], dry_run)

    click.echo("", err=True)
    click.echo("Prowlarr sync complete!", err=True)


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
        click.echo(f"  UPDATE: host config ({', '.join(update_parts)})", err=True)
        if not dry_run:
            # Update only the fields we want to change, preserve rest
            update_data = current_config.copy()
            if "bindAddress" in desired_config:
                update_data["bindAddress"] = desired_config["bindAddress"]
            client.update_host_config(update_data)
    else:
        click.echo("  OK: host config (no changes)", err=True)


def _sync_downloadclients(
    client: ArrClient, desired_clients: list, service_type: str, dry_run: bool
):
    """Sync download clients for Radarr or Sonarr."""
    current_clients = {dc["name"]: dc for dc in client.list_downloadclients()}
    desired_clients_map = {dc["name"]: dc for dc in desired_clients}

    category_fields = {
        "radarr": "movieCategory",
        "sonarr": "tvCategory",
        "lidarr": "musicCategory",
    }
    category_field = category_fields.get(service_type, "movieCategory")

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
                click.echo(f"  UPDATE: {name} ({', '.join(update_parts)})", err=True)
                if not dry_run:
                    # Build full update payload
                    update_data = current.copy()
                    update_data["fields"] = new_fields
                    client.update_downloadclient(current["id"], update_data)
            else:
                click.echo(f"  OK: {name} (no changes)", err=True)
        else:
            click.echo(f"  CREATE: {name}", err=True)
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


def _sync_rootfolders(
    client: ArrClient, desired_folders: list, dry_run: bool, **extra_kwargs
):
    """Sync root folders (declarative - delete unmanaged, create missing)."""
    current_folders = {rf["path"]: rf for rf in client.list_rootfolders()}
    desired_folders_set = set(desired_folders)

    # Delete root folders not in desired config
    for path, current in current_folders.items():
        if path not in desired_folders_set:
            click.echo(f"  DELETE: {path} (not in config)", err=True)
            if not dry_run:
                client.delete_rootfolder(current["id"])

    # Create missing root folders
    for desired_path in desired_folders:
        if desired_path in current_folders:
            click.echo(f"  OK: {desired_path} (already exists)", err=True)
        else:
            click.echo(f"  CREATE: {desired_path}", err=True)
            if not dry_run:
                name = desired_path.rstrip("/").rsplit("/", 1)[-1]
                client.create_rootfolder(desired_path, name=name, **extra_kwargs)


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
                click.echo(f"  UPDATE: {name} ({', '.join(update_parts)})", err=True)
                if not dry_run:
                    update_data = current.copy()
                    update_data["syncLevel"] = desired.get("syncLevel", "fullSync")
                    update_data["fields"] = new_fields
                    client.update_application(current["id"], update_data)
            else:
                click.echo(f"  OK: {name} (no changes)", err=True)
        else:
            click.echo(f"  CREATE: {name}", err=True)
            if not dry_run:
                # Determine implementation based on name
                name_lower = name.lower()
                if "radarr" in name_lower:
                    implementation = "Radarr"
                elif "lidarr" in name_lower:
                    implementation = "Lidarr"
                else:
                    implementation = "Sonarr"
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
            click.echo(f"  DELETE: {name} (not in config)", err=True)
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
                click.echo(f"  UPDATE: {name} ({', '.join(update_parts)})", err=True)
                if not dry_run:
                    update_data = current.copy()
                    update_data["enable"] = desired.get("enable", True)
                    update_data["priority"] = desired.get("priority", 25)
                    client.update_indexer(current["id"], update_data)
            else:
                click.echo(f"  OK: {name} (no changes)", err=True)
        else:
            # Create new indexer
            if "definitionName" not in desired:
                click.echo(
                    f"  ERROR: {name} (missing definitionName - required for creation)",
                    err=True,
                )
                continue

            click.echo(
                f"  CREATE: {name} (definitionName: {desired['definitionName']})",
                err=True,
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
