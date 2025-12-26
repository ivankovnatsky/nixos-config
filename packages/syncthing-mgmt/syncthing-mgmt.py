#!/usr/bin/env python3
"""
Syncthing configuration management tool.
Applies GUI credentials and device IDs via Syncthing REST API.
"""

import sys
import json
import time
import requests
import argparse
import xml.etree.ElementTree as ET
import bcrypt
import traceback
import os
import subprocess
import logging
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Optional, List, Dict, Any, Tuple
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich import box

USER_AGENT = "syncthing-mgmt/1.0.0"

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(message)s',
    stream=sys.stdout
)


class SyncthingClient:
    def __init__(self, base_url: str, api_key: str, timeout: int = 30,
                 max_retries: int = 5, retry_delay: float = 2.0):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.max_retries = max_retries
        self.retry_delay = retry_delay
        self.headers = {
            "User-Agent": USER_AGENT,
            "X-API-Key": api_key,
        }

    def _api_call(self, method: str, endpoint: str, data=None):
        """Make API request with error handling and retry logic."""
        url = f"{self.base_url}{endpoint}"
        last_error = None

        for attempt in range(self.max_retries):
            try:
                response = requests.request(
                    method, url, json=data, headers=self.headers, timeout=self.timeout
                )

                if response.status_code not in (200, 201, 204):
                    try:
                        error_data = response.json()
                        logging.debug(f"DEBUG: Error response: {error_data}")
                        message = error_data.get("error", "Unknown error")
                        raise Exception(
                            f"API error: {message} (Status: {response.status_code})"
                        )
                    except ValueError:
                        logging.debug(f"DEBUG: Response text: {response.text}")
                        raise Exception(
                            f"API request failed with status {response.status_code}"
                        )

                if response.status_code == 204:
                    return None

                try:
                    return response.json()
                except ValueError:
                    return {"success": True}

            except requests.exceptions.RequestException as e:
                last_error = e
                if attempt < self.max_retries - 1:
                    wait_time = self.retry_delay * (2 ** attempt)  # Exponential backoff
                    logging.info(f"    Connection error, retrying in {wait_time:.1f}s... (attempt {attempt + 1}/{self.max_retries})")
                    time.sleep(wait_time)
                    continue
                raise Exception(f"Network error after {self.max_retries} attempts: {last_error}")

    def get_config(self):
        """Get current Syncthing configuration."""
        return self._api_call("GET", "/rest/config")

    def get_gui_config(self):
        """Get GUI configuration."""
        return self._api_call("GET", "/rest/config/gui")

    def update_gui_config(self, username: str = None, password_hash: str = None):
        """Update GUI configuration with username and/or password."""
        data = {}
        if username is not None:
            data["user"] = username
        if password_hash is not None:
            data["password"] = password_hash

        if not data:
            return

        return self._api_call("PATCH", "/rest/config/gui", data=data)

    def get_devices(self):
        """Get all configured devices."""
        return self._api_call("GET", "/rest/config/devices")

    def update_device(self, device_id: str, device_config: dict):
        """Update device configuration."""
        return self._api_call("PATCH", f"/rest/config/devices/{device_id}", data=device_config)

    def add_device(self, device_id: str, name: str):
        """Add a new device."""
        data = {
            "deviceID": device_id,
            "name": name,
        }
        return self._api_call("PUT", f"/rest/config/devices/{device_id}", data=data)

    def remove_device(self, device_id: str):
        """Remove a device."""
        return self._api_call("DELETE", f"/rest/config/devices/{device_id}")

    def get_folders(self):
        """Get all configured folders."""
        return self._api_call("GET", "/rest/config/folders")

    def update_folder(self, folder_id: str, folder_config: dict):
        """Update folder configuration."""
        return self._api_call("PATCH", f"/rest/config/folders/{folder_id}", data=folder_config)

    def add_folder(self, folder_id: str, folder_config: dict):
        """Add a new folder."""
        return self._api_call("PUT", f"/rest/config/folders/{folder_id}", data=folder_config)

    def remove_folder(self, folder_id: str):
        """Remove a folder."""
        return self._api_call("DELETE", f"/rest/config/folders/{folder_id}")

    def restart_syncthing(self):
        """Restart Syncthing to apply configuration changes."""
        return self._api_call("POST", "/rest/system/restart")

    def get_connections(self):
        """Get device connection status."""
        return self._api_call("GET", "/rest/system/connections")

    def get_folder_status(self, folder_id: str):
        """Get folder status (sync state)."""
        return self._api_call("GET", f"/rest/db/status?folder={folder_id}")

    def get_completion(self, device_id: str, folder_id: str = None):
        """Get completion status for a device (syncing progress)."""
        endpoint = f"/rest/db/completion?device={device_id}"
        if folder_id:
            endpoint += f"&folder={folder_id}"
        return self._api_call("GET", endpoint)

    def get_system_status(self):
        """Get system status (includes local device ID)."""
        return self._api_call("GET", "/rest/system/status")

    def get_options(self):
        """Get Syncthing options configuration."""
        return self._api_call("GET", "/rest/config/options")

    def update_options(self, options: dict):
        """Update Syncthing options configuration."""
        return self._api_call("PATCH", "/rest/config/options", data=options)


def hash_password(password: str) -> str:
    """Hash password using bcrypt (cost factor 10)."""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(rounds=10)).decode('utf-8')


def format_bytes(bytes_val: int) -> str:
    """Format bytes into human-readable format (KB, MB, GB, TB)."""
    if bytes_val == 0:
        return "0 B"

    units = ["B", "KB", "MB", "GB", "TB"]
    unit_index = 0
    size = float(bytes_val)

    while size >= 1024 and unit_index < len(units) - 1:
        size /= 1024
        unit_index += 1

    # Show 2 decimal places for values < 10, 1 decimal for >= 10
    if size < 10:
        return f"{size:.2f} {units[unit_index]}"
    else:
        return f"{size:.1f} {units[unit_index]}"


def get_api_key_from_config(config_path: str) -> str:
    """Extract API key from Syncthing config.xml."""
    try:
        tree = ET.parse(config_path)
        root = tree.getroot()
        api_key = root.find('.//gui/apikey')
        if api_key is not None and api_key.text:
            return api_key.text
        raise Exception("API key not found in config.xml")
    except Exception as e:
        raise Exception(f"Failed to read API key from {config_path}: {e}")


def find_listening_address(port: int = 8384) -> Optional[str]:
    """
    Find what address is listening on the given port using system tools.
    Returns the listening address (e.g., '127.0.0.1', '0.0.0.0', '192.168.1.10') or None.
    """
    if sys.platform == "darwin":
        # macOS: use lsof
        try:
            result = subprocess.run(
                ["lsof", "-i", f":{port}", "-sTCP:LISTEN", "-n", "-P"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0 and result.stdout:
                # Parse lsof output - format: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME (STATE)
                # Example: syncthing 13446 ivan 17u IPv4 ... TCP 127.0.0.1:8384 (LISTEN)
                for line in result.stdout.strip().split('\n')[1:]:  # Skip header
                    parts = line.split()
                    if len(parts) >= 9:
                        # Find the address:port part (contains : and is before (LISTEN))
                        for part in reversed(parts):
                            if ':' in part and not part.startswith('('):
                                addr = part.rsplit(':', 1)[0]
                                if addr == '*':
                                    return '0.0.0.0'
                                return addr
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
    else:
        # Linux: use ss
        try:
            result = subprocess.run(
                ["ss", "-tlnH", "sport", "=", f":{port}"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0 and result.stdout:
                # Parse ss output - format: State Recv-Q Send-Q Local Address:Port Peer Address:Port
                for line in result.stdout.strip().split('\n'):
                    parts = line.split()
                    if len(parts) >= 4:
                        local_addr = parts[3]  # Local Address:Port
                        if ':' in local_addr:
                            addr = local_addr.rsplit(':', 1)[0]
                            # Handle IPv6 bracket notation
                            if addr.startswith('[') and addr.endswith(']'):
                                addr = addr[1:-1]
                            if addr == '*' or addr == '0.0.0.0' or addr == '::':
                                return '0.0.0.0'
                            return addr
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass

    return None


def get_client(args, use_fallback: bool = True):
    """
    Get a configured SyncthingClient from args.

    If use_fallback is True (default for CLI mode), will try to find a reachable
    Syncthing instance by checking what's listening on port 8384.
    """
    # Get API key
    if hasattr(args, 'api_key') and args.api_key:
        api_key = args.api_key
    elif hasattr(args, 'config_xml') and args.config_xml:
        api_key = get_api_key_from_config(args.config_xml)
    else:
        raise Exception("Either --api-key or --config-xml must be provided")

    base_url = args.base_url

    # For CLI mode, auto-detect Syncthing address from port listener
    if use_fallback and hasattr(args, 'mode') and args.mode == 'cli':
        listening_addr = find_listening_address(8384)

        if listening_addr:
            # If bound to 0.0.0.0, use localhost
            if listening_addr == '0.0.0.0':
                detected_url = "http://127.0.0.1:8384"
            else:
                detected_url = f"http://{listening_addr}:8384"

            if detected_url != base_url:
                logging.info(f"Detected Syncthing at {detected_url}")
            base_url = detected_url
        else:
            error_msg = """
No process listening on port 8384.

Please check that:
  1. Syncthing is running
  2. The correct URL is specified with --base-url
"""
            logging.error(error_msg)
            raise Exception("Syncthing is not running (nothing listening on port 8384)")

    return SyncthingClient(base_url, api_key)


def fetch_completions_parallel(
    client,
    tasks: List[Tuple[str, Optional[str]]],
    max_workers: int = 5
) -> Dict[Tuple[str, Optional[str]], Any]:
    """
    Fetch completion status for multiple device/folder combinations in parallel.

    Args:
        client: SyncthingClient instance
        tasks: List of (device_id, folder_id) tuples. folder_id can be None for device-level completion.
        max_workers: Maximum parallel requests

    Returns:
        Dict mapping (device_id, folder_id) to completion data
    """
    results = {}

    def fetch_one(task):
        device_id, folder_id = task
        try:
            return task, client.get_completion(device_id, folder_id)
        except Exception:
            return task, None

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(fetch_one, task): task for task in tasks}
        for future in as_completed(futures):
            task, result = future.result()
            if result:
                results[task] = result

    return results


def fetch_folder_statuses_parallel(
    client,
    folder_ids: List[str],
    max_workers: int = 5
) -> Dict[str, Any]:
    """
    Fetch folder statuses in parallel.

    Args:
        client: SyncthingClient instance
        folder_ids: List of folder IDs
        max_workers: Maximum parallel requests

    Returns:
        Dict mapping folder_id to status data
    """
    results = {}

    def fetch_one(folder_id):
        try:
            return folder_id, client.get_folder_status(folder_id)
        except Exception:
            return folder_id, None

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(fetch_one, fid): fid for fid in folder_ids}
        for future in as_completed(futures):
            folder_id, result = future.result()
            if result:
                results[folder_id] = result

    return results


def sync_devices(client, devices_config, dry_run=False):
    """
    Sync devices declaratively (add, update, remove).

    Args:
        client: SyncthingClient instance
        devices_config: Dict mapping device names to device IDs
        dry_run: If True, only show what would be changed
    """
    current_devices = {dev["deviceID"]: dev for dev in client.get_devices()
                       if dev and isinstance(dev, dict) and "deviceID" in dev}
    configured_device_ids = set(devices_config.values())

    logging.info(f"  Syncing devices ({len(devices_config)} configured)...")

    # Add or update devices that are in config
    for device_name, device_id in devices_config.items():
        if device_id in current_devices:
            current_name = current_devices[device_id].get("name", "")
            if current_name != device_name:
                logging.info(f"    UPDATE: {current_name} -> {device_name} ({device_id[:7]}...)")
                if not dry_run:
                    client.update_device(device_id, {"name": device_name})
                    logging.info(f"      ✓ Device name updated")
                else:
                    logging.info(f"      [DRY-RUN] Would update device name")
            else:
                logging.info(f"    OK: {device_name} ({device_id[:7]}...) already configured")
        else:
            logging.info(f"    ADD: {device_name} ({device_id[:7]}...)")
            if not dry_run:
                client.add_device(device_id, device_name)
                logging.info(f"      ✓ Device added")
            else:
                logging.info(f"      [DRY-RUN] Would add device")

    # Remove devices that are in Syncthing but not in config
    for device_id, device in current_devices.items():
        if device_id not in configured_device_ids:
            device_name = device.get("name", "Unknown")
            logging.info(f"    REMOVE: {device_name} ({device_id[:7]}...)")
            if not dry_run:
                client.remove_device(device_id)
                logging.info(f"      ✓ Device removed")
            else:
                logging.info(f"      [DRY-RUN] Would remove device")


def sync_folders(client, folders_config, devices_config, dry_run=False):
    """
    Sync folders declaratively (add, update, remove).

    Args:
        client: SyncthingClient instance
        folders_config: Dict mapping folder IDs to folder configurations
        devices_config: Dict mapping device names to device IDs (for resolution)
        dry_run: If True, only show what would be changed
    """
    current_folders = {f["id"]: f for f in client.get_folders()
                       if f and isinstance(f, dict) and "id" in f}
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
            current_devices = set(d.get("deviceID") for d in current_folder.get("devices", [])
                                  if d and isinstance(d, dict))

            new_label = folder_cfg.get("label", folder_id)
            new_path = folder_cfg["path"]
            new_devices = set(resolved_device_ids)

            # Check if anything changed
            if current_label != new_label or current_path != new_path or current_devices != new_devices:
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
                    logging.info(f"      ✓ Folder updated")
                else:
                    logging.info(f"      [DRY-RUN] Would update folder")
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
                logging.info(f"      ✓ Folder added")
            else:
                logging.info(f"      [DRY-RUN] Would add folder")

    # Remove folders that are in Syncthing but not in config
    for folder_id, folder in current_folders.items():
        if folder_id not in configured_folder_ids:
            folder_label = folder.get("label", folder_id)
            logging.info(f"    REMOVE: {folder_label} ({folder_id})")
            if not dry_run:
                client.remove_folder(folder_id)
                logging.info(f"      ✓ Folder removed")
            else:
                logging.info(f"      [DRY-RUN] Would remove folder")


def sync_local_device_name(client, device_name: str, dry_run=False):
    """
    Sync the local device name.

    Args:
        client: SyncthingClient instance
        device_name: Desired name for this device
        dry_run: If True, only show what would be changed
    """
    logging.info(f"  Syncing local device name...")

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
        logging.error(f"    Could not find local device config for ID {local_device_id[:7]}...")
        return

    current_name = local_device.get("name", "")
    if current_name == device_name:
        logging.info(f"    OK: Local device name already set to '{device_name}'")
        return

    logging.info(f"    UPDATE: '{current_name}' -> '{device_name}' ({local_device_id[:7]}...)")
    if not dry_run:
        client.update_device(local_device_id, {"name": device_name})
        logging.info(f"      ✓ Local device name updated")
    else:
        logging.info(f"      [DRY-RUN] Would update local device name")


def cmd_sync(args):
    """Sync GUI credentials and devices from configuration file."""
    try:
        # Load configuration
        with open(args.config_file, "r") as f:
            config = json.load(f)

        client = get_client(args)

        logging.info("Syncing Syncthing configuration...")

        # Sync local device name if present
        if "localDeviceName" in config and config["localDeviceName"]:
            sync_local_device_name(client, config["localDeviceName"], dry_run=args.dry_run)

        # Sync GUI credentials if present
        if "gui" in config and config["gui"] is not None:
            gui_config = config["gui"]
            username = gui_config.get("username")
            password = gui_config.get("password")

            if username or password:
                logging.info(f"  Updating GUI credentials...")

                # Hash password if needed
                password_hash = None
                if password:
                    # Check if it's already a bcrypt hash
                    if password.startswith("$2"):
                        password_hash = password
                        logging.info(f"    Using pre-hashed password")
                    else:
                        password_hash = hash_password(password)
                        logging.info(f"    Hashed plain text password with bcrypt")

                if not args.dry_run:
                    client.update_gui_config(username=username, password_hash=password_hash)
                    logging.info(f"    ✓ GUI credentials updated")
                else:
                    logging.info(f"    [DRY-RUN] Would update GUI credentials")

        # Sync devices if present (fully declarative - add and remove)
        if "devices" in config:
            sync_devices(client, config["devices"], dry_run=args.dry_run)

        # Sync folders if present (fully declarative - add and remove)
        if "folders" in config:
            devices_config = config.get("devices", {})
            sync_folders(client, config["folders"], devices_config, dry_run=args.dry_run)

        if args.dry_run:
            logging.info("")
            logging.info("Dry-run complete - no changes made")
        else:
            logging.info("")
            logging.info("Sync complete!")

            if args.restart:
                logging.info("Restarting Syncthing...")
                client.restart_syncthing()
                logging.info("Restart initiated")

    except Exception as e:
        logging.error(f"Error: {e}")
        logging.info("\nFull traceback:")
        traceback.print_exc(file=sys.stderr)
        sys.exit(1)


def display_this_device(system_status, connections_data=None):
    """Display information about this device."""
    if not system_status:
        return

    console = Console()
    console.print()  # Add blank line
    console.print("[bold cyan]This Device[/bold cyan]")

    # Create table
    table = Table(
        show_header=False,
        show_lines=False,
        box=box.ROUNDED,
        padding=(0, 1)
    )
    table.add_column("Property", style="dim", width=25)
    table.add_column("Value", style="bold")

    # Download/Upload Rate
    if connections_data:
        total_in_rate = connections_data.get("total", {}).get("inBytesTotal", 0)
        total_out_rate = connections_data.get("total", {}).get("outBytesTotal", 0)
        in_rate = format_bytes(0)  # Current rate not available in REST API
        out_rate = format_bytes(0)
        total_in_str = format_bytes(total_in_rate)
        total_out_str = format_bytes(total_out_rate)
        table.add_row("Download Rate", f"0 B/s ({total_in_str})")
        table.add_row("Upload Rate", f"0 B/s ({total_out_str})")

    # Local State (Total) - we'll need to aggregate folder stats
    # For now, skip this as it requires iterating through all folders

    # Listeners
    num_listeners = system_status.get("connectionServiceStatus", {})
    if num_listeners:
        active = sum(1 for svc, status in num_listeners.items() if status.get("error") is None)
        total = len(num_listeners)
        table.add_row("Listeners", f"{active}/{total}")

    # Discovery
    discovery_status = system_status.get("discoveryStatus", {})
    if discovery_status:
        active = sum(1 for svc, status in discovery_status.items() if status.get("error") is None)
        total = len(discovery_status)
        table.add_row("Discovery", f"{active}/{total}")

    # Uptime
    uptime_sec = system_status.get("uptime", 0)
    if uptime_sec:
        days = uptime_sec // 86400
        hours = (uptime_sec % 86400) // 3600
        minutes = (uptime_sec % 3600) // 60
        uptime_str = f"{days}d {hours}h {minutes}m"
        table.add_row("Uptime", uptime_str)

    # Identification (short device ID)
    device_id = system_status.get("myID", "")
    if device_id:
        short_id = device_id[:7]
        table.add_row("Identification", short_id)

    # Version
    version = system_status.get("version", "")
    os_info = system_status.get("os", "")
    arch = system_status.get("arch", "")
    if version:
        version_str = f"{version}"
        if os_info or arch:
            version_str += f", {os_info}"
            if arch:
                version_str += f" ({arch})"
        table.add_row("Version", version_str)

    console.print(table)


def display_devices(devices, detailed=False, connections=None, completions=None):
    """Display devices in a formatted table."""
    console = Console()
    console.print()  # Add blank line
    console.print("[bold cyan]Remote Devices[/bold cyan]")

    if not devices:
        print("  (none)")
        return

    # Create table
    table = Table(
        show_header=True,
        header_style="bold cyan",
        show_lines=False,
        box=box.ROUNDED
    )
    table.add_column("Devices", style="bold yellow")
    table.add_column("Device ID", style="dim")
    table.add_column("Connection Status", justify="center")
    table.add_column("Sync Status")

    for device in devices:
        if not device or not isinstance(device, dict):
            continue
        name = device.get("name", "Unknown")
        device_id = device.get("deviceID", "")
        device_id_short = device_id[:7] + "..." if device_id else ""

        # Get connection status
        conn_status = ""
        sync_status = ""
        if connections and device_id in connections:
            conn = connections[device_id]
            if conn.get("paused"):
                conn_status = "[yellow]Paused[/yellow]"
            elif conn.get("connected"):
                conn_status = "[green]Connected[/green]"
                # Check if syncing
                if completions and device_id in completions:
                    comp = completions[device_id]
                    completion_pct = comp.get("completion", 100)
                    if completion_pct < 100:
                        # Show syncing progress
                        need_bytes = comp.get("needBytes", 0)
                        need_size = format_bytes(need_bytes)
                        sync_status = f"[cyan]Syncing {completion_pct:.0f}%[/cyan], {need_size}"
                    else:
                        sync_status = "[green]Up to Date[/green]"
            else:
                conn_status = "[red]Disconnected[/red]"
        else:
            conn_status = "[dim]Unknown[/dim]"

        table.add_row(name, device_id_short, conn_status, sync_status)

    # Print the table
    console.print(table)


def display_folders(folders, detailed=False, device_map=None, folder_statuses=None, local_device_id=None, device_completions=None):
    """
    Display folders in a formatted table.

    Args:
        folders: List of folder configs
        detailed: Show detailed info including folder IDs
        device_map: Dict mapping device IDs to device names (for resolving shared devices)
        folder_statuses: Dict mapping folder IDs to status info
        local_device_id: Local device ID to filter out from shared devices
        device_completions: Dict mapping (device_id, folder_id) tuples to completion info
    """
    console = Console()
    console.print("[bold cyan]Folders[/bold cyan]")

    if not folders:
        print("  (none)")
        return

    # Create table
    table = Table(
        show_header=True,
        header_style="bold cyan",
        show_lines=False,
        box=box.ROUNDED
    )
    table.add_column("Folders", style="bold")
    table.add_column("Devices", style="yellow")
    table.add_column("Sync Status", style="green")

    first_folder = True
    for folder in folders:
        if not folder or not isinstance(folder, dict):
            continue

        # Add section divider between folders
        if not first_folder:
            table.add_section()
        first_folder = False

        folder_id = folder.get("id", "")
        label = folder.get("label", folder_id)
        path = folder.get("path", "")
        devices = folder.get("devices", [])

        # Get devices to display (excluding local device)
        devices_to_show = []
        for d in devices:
            if d and isinstance(d, dict):
                dev_id = d.get("deviceID", "")
                if local_device_id and dev_id == local_device_id:
                    continue
                devices_to_show.append(d)

        # Build device info list
        device_rows = []
        for d in devices_to_show:
            dev_id = d.get("deviceID", "")

            # Get device name
            if device_map and dev_id in device_map:
                dev_name = device_map[dev_id]
            else:
                dev_name = dev_id[:7] + "..."

            # Get sync status
            sync_status = ""
            if device_completions and (dev_id, folder_id) in device_completions:
                comp = device_completions[(dev_id, folder_id)]
                need_items = comp.get("needItems", 0)
                need_bytes = comp.get("needBytes", 0)

                if need_items > 0:
                    items_str = f"{need_items:,} item{'s' if need_items != 1 else ''}"
                    bytes_str = format_bytes(need_bytes)
                    sync_status = f"[red]Out of Sync:[/red] {items_str}, ~{bytes_str}"
                else:
                    sync_status = "[green]Up to Date[/green]"

            device_rows.append((dev_name, sync_status))

        # Add rows: first row has label, second row has path, rest are empty
        if device_rows:
            # First row: folder label + first device
            table.add_row(label, device_rows[0][0], device_rows[0][1])
            # Second row: path + second device (or just path if only one device)
            if len(device_rows) > 1:
                table.add_row(f"[dim]{path}[/dim]", device_rows[1][0], device_rows[1][1])
            else:
                table.add_row(f"[dim]{path}[/dim]", "", "")
            # Remaining devices
            for idx in range(2, len(device_rows)):
                table.add_row("", device_rows[idx][0], device_rows[idx][1])
        else:
            # No devices to show
            table.add_row(label, "(none)", "")
            table.add_row(f"[dim]{path}[/dim]", "", "")

    # Print the table
    console.print(table)


def cmd_list_devices(args):
    """List all configured devices."""
    try:
        client = get_client(args)

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
                connections = connections_data.get("connections", {}) if connections_data else {}
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

        display_devices(devices, detailed=True, connections=connections, completions=completions)

    except Exception as e:
        logging.error(f"Error: {e}")
        sys.exit(1)


def cmd_list_folders(args):
    """List all configured folders."""
    try:
        client = get_client(args)

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
        device_map = {d.get("deviceID"): d.get("name", "Unknown")
                      for d in devices if d and isinstance(d, dict) and "deviceID" in d}

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
        folder_ids = [f["id"] for f in folders if f and isinstance(f, dict) and "id" in f]
        with ThreadPoolExecutor(max_workers=2) as executor:
            future_completions = executor.submit(fetch_completions_parallel, client, completion_tasks)
            future_folder_statuses = executor.submit(fetch_folder_statuses_parallel, client, folder_ids)

            device_completions = future_completions.result()
            folder_statuses = future_folder_statuses.result()

        display_folders(folders, detailed=True, device_map=device_map, folder_statuses=folder_statuses, local_device_id=local_device_id, device_completions=device_completions)

    except Exception as e:
        logging.error(f"Error: {e}")
        sys.exit(1)


def cmd_status(args):
    """Show status of configured devices and folders."""
    try:
        client = get_client(args)

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
                connections = connections_data.get("connections", {}) if connections_data else {}
            except Exception:
                connections_data = None
                connections = None

        # Filter out the local device
        if local_device_id:
            devices = [d for d in devices if d.get("deviceID") != local_device_id]

        # Build device ID to name map for folder display
        device_map = {d.get("deviceID"): d.get("name", "Unknown")
                      for d in devices if d and isinstance(d, dict) and "deviceID" in d}

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
        folder_ids = [f["id"] for f in folders if f and isinstance(f, dict) and "id" in f]
        with ThreadPoolExecutor(max_workers=2) as executor:
            future_completions = executor.submit(fetch_completions_parallel, client, completion_tasks)
            future_folder_statuses = executor.submit(fetch_folder_statuses_parallel, client, folder_ids)

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
        display_folders(folders, detailed=False, device_map=device_map, folder_statuses=folder_statuses, local_device_id=local_device_id, device_completions=device_completions)

        # Display this device
        display_this_device(system_status, connections_data)

        # Display devices
        display_devices(devices, detailed=False, connections=connections, completions=completions)

    except Exception as e:
        logging.error(f"Error: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Syncthing configuration management tool",
        epilog="Default mode: CLI (use 'syncthing-mgmt' or 'syncthing-mgmt cli status')"
    )

    # Main subparsers for declarative vs cli mode
    mode_subparsers = parser.add_subparsers(
        dest="mode", help="Operation mode"
    )

    # ===== CLI Mode (interactive, default) =====
    cli_parser = mode_subparsers.add_parser(
        "cli", help="CLI mode for interactive use (default)"
    )
    cli_subparsers = cli_parser.add_subparsers(
        dest="cli_command", help="CLI command to execute"
    )

    # Common arguments for CLI commands
    def add_cli_args(subparser):
        subparser.add_argument("--base-url",
                             help="Syncthing URL (default: http://127.0.0.1:8384, with fallback to local IPs)")
        subparser.add_argument("--api-key", help="Syncthing API key")
        subparser.add_argument("--config-xml", help="Path to Syncthing config.xml (to extract API key)")

    # CLI: status command
    status_parser = cli_subparsers.add_parser(
        "status", help="Show status of configured devices and folders (default)"
    )
    add_cli_args(status_parser)

    # CLI: list command with subcommands
    list_parser = cli_subparsers.add_parser(
        "list", help="List configured resources"
    )
    list_subparsers = list_parser.add_subparsers(
        dest="list_command", help="Resource type to list"
    )

    # CLI: list devices
    list_devices_parser = list_subparsers.add_parser(
        "devices", help="List all configured devices"
    )
    add_cli_args(list_devices_parser)

    # CLI: list folders
    list_folders_parser = list_subparsers.add_parser(
        "folders", help="List all configured folders"
    )
    add_cli_args(list_folders_parser)

    # ===== Declarative Mode (for NixOS/Darwin modules) =====
    declarative_parser = mode_subparsers.add_parser(
        "declarative", help="Declarative mode for NixOS/Darwin modules"
    )
    declarative_parser.add_argument("--base-url", required=True, help="Syncthing URL")
    declarative_parser.add_argument("--api-key", help="Syncthing API key")
    declarative_parser.add_argument("--config-xml", help="Path to Syncthing config.xml (to extract API key)")
    declarative_parser.add_argument(
        "--config-file", required=True, help="JSON configuration file"
    )
    declarative_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without making changes",
    )
    declarative_parser.add_argument(
        "--restart",
        action="store_true",
        help="Restart Syncthing after applying changes",
    )

    args = parser.parse_args()

    # Default to CLI mode with status command if no mode specified
    if not args.mode:
        args.mode = "cli"
        args.cli_command = "status"
        args.base_url = None
        args.api_key = None
        args.config_xml = None

    # Default to status for CLI mode if no command specified
    if args.mode == "cli" and not args.cli_command:
        args.cli_command = "status"

    # Try to auto-detect config.xml for CLI mode
    if args.mode == "cli":
        if not args.config_xml and not args.api_key:
            # Try common config locations (Linux and Darwin)
            possible_configs = [
                # Linux (user)
                os.path.expanduser("~/.local/state/syncthing/config.xml"),
                os.path.expanduser("~/.config/syncthing/config.xml"),
                # Linux (system)
                "/var/lib/syncthing/.config/syncthing/config.xml",
                # Darwin (macOS)
                os.path.expanduser("~/Library/Application Support/Syncthing/config.xml"),
            ]
            for config_path in possible_configs:
                if os.path.exists(config_path):
                    args.config_xml = config_path
                    break

        # Default base URL to localhost if not provided
        if not args.base_url:
            args.base_url = "http://127.0.0.1:8384"

    # Route to appropriate command
    if args.mode == "declarative":
        cmd_sync(args)
    elif args.mode == "cli":
        if args.cli_command == "list":
            if hasattr(args, 'list_command') and args.list_command == "devices":
                cmd_list_devices(args)
            elif hasattr(args, 'list_command') and args.list_command == "folders":
                cmd_list_folders(args)
            else:
                list_parser.print_help()
        elif args.cli_command == "status":
            cmd_status(args)


if __name__ == "__main__":
    main()
