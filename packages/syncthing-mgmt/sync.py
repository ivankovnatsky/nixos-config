"""Declarative sync operations: devices, folders, local device name, and cmd_sync."""

import sys
import json
import logging
import traceback

from utils import hash_password, get_client


def sync_devices(client, devices_config, dry_run=False):
    """
    Sync devices declaratively (add, update, remove).

    Args:
        client: SyncthingClient instance
        devices_config: Dict mapping device names to device IDs
        dry_run: If True, only show what would be changed
    """
    current_devices = {
        dev["deviceID"]: dev
        for dev in client.get_devices()
        if dev and isinstance(dev, dict) and "deviceID" in dev
    }
    configured_device_ids = set(devices_config.values())

    logging.info(f"  Syncing devices ({len(devices_config)} configured)...")

    # Add or update devices that are in config
    for device_name, device_id in devices_config.items():
        if device_id in current_devices:
            current_name = current_devices[device_id].get("name", "")
            if current_name != device_name:
                logging.info(
                    f"    UPDATE: {current_name} -> {device_name} ({device_id[:7]}...)"
                )
                if not dry_run:
                    client.update_device(device_id, {"name": device_name})
                    logging.info("      ✓ Device name updated")
                else:
                    logging.info("      [DRY-RUN] Would update device name")
            else:
                logging.info(
                    f"    OK: {device_name} ({device_id[:7]}...) already configured"
                )
        else:
            logging.info(f"    ADD: {device_name} ({device_id[:7]}...)")
            if not dry_run:
                client.add_device(device_id, device_name)
                logging.info("      ✓ Device added")
            else:
                logging.info("      [DRY-RUN] Would add device")

    # Remove devices that are in Syncthing but not in config
    for device_id, device in current_devices.items():
        if device_id not in configured_device_ids:
            device_name = device.get("name", "Unknown")
            logging.info(f"    REMOVE: {device_name} ({device_id[:7]}...)")
            if not dry_run:
                client.remove_device(device_id)
                logging.info("      ✓ Device removed")
            else:
                logging.info("      [DRY-RUN] Would remove device")


def sync_folders(client, folders_config, devices_config, dry_run=False):
    """
    Sync folders declaratively (add, update, remove).

    Args:
        client: SyncthingClient instance
        folders_config: Dict mapping folder IDs to folder configurations
        devices_config: Dict mapping device names to device IDs (for resolution)
        dry_run: If True, only show what would be changed
    """
    current_folders = {
        f["id"]: f
        for f in client.get_folders()
        if f and isinstance(f, dict) and "id" in f
    }
    configured_folder_ids = set(folders_config.keys())

    # Build device name to ID mapping for resolving device references
    device_name_to_id = {name: dev_id for name, dev_id in devices_config.items()}

    logging.info(f"  Syncing folders ({len(folders_config)} configured)...")

    # Add or update folders that are in config
    for folder_id, folder_cfg in folders_config.items():
        # Resolve device names/IDs to device IDs
        configured_devices = folder_cfg.get("devices", [])
        resolved_device_ids = []
        for dev in configured_devices:
            # Check if it's a device name (exists in mapping) or already a device ID
            if dev in device_name_to_id:
                resolved_device_ids.append(device_name_to_id[dev])
            else:
                # Assume it's already a device ID
                resolved_device_ids.append(dev)

        if folder_id in current_folders:
            current_folder = current_folders[folder_id]
            current_label = current_folder.get("label", "")
            current_path = current_folder.get("path", "")
            current_devices = set(
                d.get("deviceID")
                for d in current_folder.get("devices", [])
                if d and isinstance(d, dict)
            )

            new_label = folder_cfg.get("label", folder_id)
            new_path = folder_cfg["path"]
            new_devices = set(resolved_device_ids)

            # Check if anything changed
            if (
                current_label != new_label
                or current_path != new_path
                or current_devices != new_devices
            ):
                logging.info(f"    UPDATE: {folder_id}")
                if not dry_run:
                    # Build device list for API
                    devices_list = [{"deviceID": dev_id} for dev_id in new_devices]
                    update_data = {
                        "label": new_label,
                        "path": new_path,
                        "devices": devices_list,
                    }
                    client.update_folder(folder_id, update_data)
                    logging.info("      ✓ Folder updated")
                else:
                    logging.info("      [DRY-RUN] Would update folder")
            else:
                logging.info(f"    OK: {folder_id} already configured")
        else:
            logging.info(f"    ADD: {folder_id}")
            if not dry_run:
                # Build device list for API
                devices_list = [{"deviceID": dev_id} for dev_id in resolved_device_ids]
                add_data = {
                    "id": folder_id,
                    "label": folder_cfg.get("label", folder_id),
                    "path": folder_cfg["path"],
                    "devices": devices_list,
                }
                client.add_folder(folder_id, add_data)
                logging.info("      ✓ Folder added")
            else:
                logging.info("      [DRY-RUN] Would add folder")

        # Sync per-folder ignore patterns
        desired_ignores = folder_cfg.get("ignorePatterns", [])
        try:
            resp = client.get_folder_ignores(folder_id)
            current_ignores = resp.get("ignore", []) if resp else []
        except Exception:
            current_ignores = []
        if current_ignores != desired_ignores:
            logging.info(f"    SET ignores: {folder_id}")
            if not dry_run:
                client.set_folder_ignores(folder_id, desired_ignores)
                logging.info("      ✓ Folder ignores updated")
            else:
                logging.info("      [DRY-RUN] Would update folder ignores")
        else:
            logging.info(f"    OK: {folder_id} ignores already configured")

    # Remove folders that are in Syncthing but not in config
    for folder_id, folder in current_folders.items():
        if folder_id not in configured_folder_ids:
            folder_label = folder.get("label", folder_id)
            logging.info(f"    REMOVE: {folder_label} ({folder_id})")
            if not dry_run:
                client.remove_folder(folder_id)
                logging.info("      ✓ Folder removed")
            else:
                logging.info("      [DRY-RUN] Would remove folder")


def sync_local_device_name(client, device_name: str, dry_run=False):
    """
    Sync the local device name.

    Args:
        client: SyncthingClient instance
        device_name: Desired name for this device
        dry_run: If True, only show what would be changed
    """
    logging.info("  Syncing local device name...")

    # Get local device ID
    system_status = client.get_system_status()
    local_device_id = system_status.get("myID")
    if not local_device_id:
        logging.error("    Could not determine local device ID")
        return

    # Get current device config
    devices = client.get_devices()
    local_device = None
    for dev in devices:
        if dev and isinstance(dev, dict) and dev.get("deviceID") == local_device_id:
            local_device = dev
            break

    if not local_device:
        logging.error(
            f"    Could not find local device config for ID {local_device_id[:7]}..."
        )
        return

    current_name = local_device.get("name", "")
    if current_name == device_name:
        logging.info(f"    OK: Local device name already set to '{device_name}'")
        return

    logging.info(
        f"    UPDATE: '{current_name}' -> '{device_name}' ({local_device_id[:7]}...)"
    )
    if not dry_run:
        client.update_device(local_device_id, {"name": device_name})
        logging.info("      ✓ Local device name updated")
    else:
        logging.info("      [DRY-RUN] Would update local device name")


def cmd_sync(base_url, api_key, config_xml, config_file, dry_run=False, restart=False):
    """Sync GUI credentials and devices from configuration file."""
    try:
        # Load configuration
        with open(config_file, "r") as f:
            config = json.load(f)

        client = get_client(
            base_url=base_url,
            api_key=api_key,
            config_xml=config_xml,
            mode="declarative",
        )

        logging.info("Syncing Syncthing configuration...")

        # Sync local device name if present
        if "localDeviceName" in config and config["localDeviceName"]:
            sync_local_device_name(client, config["localDeviceName"], dry_run=dry_run)

        # Sync GUI credentials if present
        if "gui" in config and config["gui"] is not None:
            gui_config = config["gui"]
            username = gui_config.get("username")
            password = gui_config.get("password")

            if username or password:
                logging.info("  Updating GUI credentials...")

                # Hash password if needed
                password_hash = None
                if password:
                    # Check if it's already a bcrypt hash
                    if password.startswith("$2"):
                        password_hash = password
                        logging.info("    Using pre-hashed password")
                    else:
                        password_hash = hash_password(password)
                        logging.info("    Hashed plain text password with bcrypt")

                if not dry_run:
                    client.update_gui_config(
                        username=username, password_hash=password_hash
                    )
                    logging.info("    ✓ GUI credentials updated")
                else:
                    logging.info("    [DRY-RUN] Would update GUI credentials")

        # Sync devices if present (fully declarative - add and remove)
        if "devices" in config:
            sync_devices(client, config["devices"], dry_run=dry_run)

        # Sync folders if present (fully declarative - add and remove)
        if "folders" in config:
            devices_config = config.get("devices", {})
            sync_folders(client, config["folders"], devices_config, dry_run=dry_run)

        if dry_run:
            logging.info("")
            logging.info("Dry-run complete - no changes made")
        else:
            logging.info("")
            logging.info("Sync complete!")

            if restart:
                logging.info("Restarting Syncthing...")
                client.restart_syncthing()
                logging.info("Restart initiated")

    except Exception as e:
        logging.error(f"Error: {e}")
        logging.info("\nFull traceback:")
        traceback.print_exc(file=sys.stderr)
        sys.exit(1)
