"""CLI command handlers: status, list devices, list folders, scan."""

import sys
import logging
from concurrent.futures import ThreadPoolExecutor

from utils import get_client, fetch_completions_parallel, fetch_folder_statuses_parallel
from display import display_this_device, display_devices, display_folders


def cmd_list_devices(base_url, api_key, config_xml, mode="cli"):
    """List all configured devices."""
    try:
        client = get_client(
            base_url=base_url, api_key=api_key, config_xml=config_xml, mode=mode
        )

        # Fetch initial data in parallel
        with ThreadPoolExecutor(max_workers=3) as executor:
            future_devices = executor.submit(client.get_devices)
            future_status = executor.submit(client.get_system_status)
            future_connections = executor.submit(client.get_connections)

            devices = future_devices.result()
            try:
                system_status = future_status.result()
                local_device_id = system_status.get("myID") if system_status else None
            except Exception:
                local_device_id = None
            try:
                connections_data = future_connections.result()
                connections = (
                    connections_data.get("connections", {}) if connections_data else {}
                )
            except Exception:
                connections = None

        # Filter out the local device
        if local_device_id:
            devices = [d for d in devices if d.get("deviceID") != local_device_id]

        # Get completion status for connected devices in parallel
        completion_tasks = []
        if connections:
            for device_id, conn in connections.items():
                if conn.get("connected"):
                    completion_tasks.append((device_id, None))

        all_completions = fetch_completions_parallel(client, completion_tasks)
        completions = {dev_id: comp for (dev_id, _), comp in all_completions.items()}

        display_devices(
            devices, detailed=True, connections=connections, completions=completions
        )

    except Exception as e:
        logging.error(f"Error: {e}")
        sys.exit(1)


def cmd_list_folders(base_url, api_key, config_xml, mode="cli"):
    """List all configured folders."""
    try:
        client = get_client(
            base_url=base_url, api_key=api_key, config_xml=config_xml, mode=mode
        )

        # Fetch initial data in parallel
        with ThreadPoolExecutor(max_workers=3) as executor:
            future_devices = executor.submit(client.get_devices)
            future_folders = executor.submit(client.get_folders)
            future_status = executor.submit(client.get_system_status)

            devices = future_devices.result()
            folders = future_folders.result()
            try:
                system_status = future_status.result()
                local_device_id = system_status.get("myID") if system_status else None
            except Exception:
                local_device_id = None

        # Build device ID to name map
        device_map = {
            d.get("deviceID"): d.get("name", "Unknown")
            for d in devices
            if d and isinstance(d, dict) and "deviceID" in d
        }

        # Collect completion tasks for parallel fetching
        completion_tasks = []
        for folder in folders:
            if folder and isinstance(folder, dict) and "id" in folder:
                folder_id = folder["id"]
                folder_devices = folder.get("devices", [])
                for d in folder_devices:
                    if d and isinstance(d, dict):
                        dev_id = d.get("deviceID", "")
                        if local_device_id and dev_id == local_device_id:
                            continue
                        completion_tasks.append((dev_id, folder_id))

        # Fetch all completions and folder statuses in parallel
        folder_ids = [
            f["id"] for f in folders if f and isinstance(f, dict) and "id" in f
        ]
        with ThreadPoolExecutor(max_workers=2) as executor:
            future_completions = executor.submit(
                fetch_completions_parallel, client, completion_tasks
            )
            future_folder_statuses = executor.submit(
                fetch_folder_statuses_parallel, client, folder_ids
            )

            device_completions = future_completions.result()
            folder_statuses = future_folder_statuses.result()

        display_folders(
            folders,
            detailed=True,
            device_map=device_map,
            folder_statuses=folder_statuses,
            local_device_id=local_device_id,
            device_completions=device_completions,
        )

    except Exception as e:
        logging.error(f"Error: {e}")
        sys.exit(1)


def cmd_status(base_url, api_key, config_xml, mode="cli"):
    """Show status of configured devices and folders."""
    try:
        client = get_client(
            base_url=base_url, api_key=api_key, config_xml=config_xml, mode=mode
        )

        # Fetch initial data in parallel
        with ThreadPoolExecutor(max_workers=4) as executor:
            future_devices = executor.submit(client.get_devices)
            future_folders = executor.submit(client.get_folders)
            future_status = executor.submit(client.get_system_status)
            future_connections = executor.submit(client.get_connections)

            devices = future_devices.result()
            folders = future_folders.result()
            try:
                system_status = future_status.result()
                local_device_id = system_status.get("myID") if system_status else None
            except Exception:
                system_status = None
                local_device_id = None
            try:
                connections_data = future_connections.result()
                connections = (
                    connections_data.get("connections", {}) if connections_data else {}
                )
            except Exception:
                connections_data = None
                connections = None

        # Filter out the local device
        if local_device_id:
            devices = [d for d in devices if d.get("deviceID") != local_device_id]

        # Build device ID to name map for folder display
        device_map = {
            d.get("deviceID"): d.get("name", "Unknown")
            for d in devices
            if d and isinstance(d, dict) and "deviceID" in d
        }

        # Collect all completion tasks for parallel fetching
        completion_tasks = []

        # Device-level completions (for connected devices only)
        if connections:
            for device_id, conn in connections.items():
                if conn.get("connected"):
                    completion_tasks.append((device_id, None))

        # Device-folder completions (all devices, not just connected)
        for folder in folders:
            if folder and isinstance(folder, dict) and "id" in folder:
                folder_id = folder["id"]
                folder_devices = folder.get("devices", [])
                for d in folder_devices:
                    if d and isinstance(d, dict):
                        dev_id = d.get("deviceID", "")
                        if local_device_id and dev_id == local_device_id:
                            continue
                        completion_tasks.append((dev_id, folder_id))

        # Fetch completions and folder statuses in parallel
        folder_ids = [
            f["id"] for f in folders if f and isinstance(f, dict) and "id" in f
        ]
        with ThreadPoolExecutor(max_workers=2) as executor:
            future_completions = executor.submit(
                fetch_completions_parallel, client, completion_tasks
            )
            future_folder_statuses = executor.submit(
                fetch_folder_statuses_parallel, client, folder_ids
            )

            all_completions = future_completions.result()
            folder_statuses = future_folder_statuses.result()

        # Split results into device-level and folder-level completions
        completions = {}
        device_completions = {}
        for (dev_id, folder_id), comp in all_completions.items():
            if folder_id is None:
                completions[dev_id] = comp
            else:
                device_completions[(dev_id, folder_id)] = comp

        # Display folders with device name resolution
        display_folders(
            folders,
            detailed=False,
            device_map=device_map,
            folder_statuses=folder_statuses,
            local_device_id=local_device_id,
            device_completions=device_completions,
        )

        # Display this device
        display_this_device(system_status, connections_data)

        # Display devices
        display_devices(
            devices, detailed=False, connections=connections, completions=completions
        )

    except Exception as e:
        logging.error(f"Error: {e}")
        sys.exit(1)


def cmd_scan(base_url, api_key, config_xml, mode="cli", folders=None):
    """Trigger a rescan for folders."""
    try:
        client = get_client(
            base_url=base_url, api_key=api_key, config_xml=config_xml, mode=mode
        )
        folders_to_scan = folders or []

        if not folders_to_scan:
            all_folders = client.get_folders()
            folders_to_scan = [
                f["id"] for f in all_folders if f and isinstance(f, dict) and "id" in f
            ]

        for folder_id in folders_to_scan:
            logging.info(f"Scanning {folder_id}...")
            client.scan_folder(folder_id)
            logging.info("  ✓ Scan triggered")

    except Exception as e:
        logging.error(f"Error: {e}")
        sys.exit(1)
