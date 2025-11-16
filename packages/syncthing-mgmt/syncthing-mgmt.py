#!/usr/bin/env python3
"""
Syncthing configuration management tool.
Applies GUI credentials and device IDs via Syncthing REST API.
"""

import sys
import json
import requests
import argparse
import xml.etree.ElementTree as ET
import bcrypt
import traceback
import os
import socket
from typing import Optional, Tuple, List

USER_AGENT = "syncthing-mgmt/1.0.0"


class SyncthingClient:
    def __init__(self, base_url: str, api_key: str, timeout: int = 30):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.headers = {
            "User-Agent": USER_AGENT,
            "X-API-Key": api_key,
        }

    def _api_call(self, method: str, endpoint: str, data=None):
        """Make API request with error handling."""
        url = f"{self.base_url}{endpoint}"
        try:
            response = requests.request(
                method, url, json=data, headers=self.headers, timeout=self.timeout
            )

            if response.status_code not in (200, 201, 204):
                try:
                    error_data = response.json()
                    print(f"DEBUG: Error response: {error_data}", file=sys.stderr)
                    message = error_data.get("error", "Unknown error")
                    raise Exception(
                        f"API error: {message} (Status: {response.status_code})"
                    )
                except ValueError:
                    print(f"DEBUG: Response text: {response.text}", file=sys.stderr)
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
            raise Exception(f"Network error: {e}")

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


def hash_password(password: str) -> str:
    """Hash password using bcrypt (cost factor 10)."""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(rounds=10)).decode('utf-8')


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


def get_local_ip_addresses() -> List[str]:
    """Get all local IP addresses (excluding loopback)."""
    ips = []
    try:
        # Get hostname and resolve all associated IPs
        hostname = socket.gethostname()
        for info in socket.getaddrinfo(hostname, None):
            ip = info[4][0]
            # Skip loopback and IPv6
            if not ip.startswith('127.') and ':' not in ip:
                if ip not in ips:
                    ips.append(ip)
    except Exception:
        pass
    return ips


def check_syncthing_reachable(base_url: str, api_key: str, timeout: int = 3) -> bool:
    """Check if Syncthing API is reachable at the given URL."""
    try:
        url = f"{base_url.rstrip('/')}/rest/system/status"
        headers = {
            "User-Agent": USER_AGENT,
            "X-API-Key": api_key,
        }
        response = requests.get(url, headers=headers, timeout=timeout)
        return response.status_code == 200
    except (requests.exceptions.ConnectionError,
            requests.exceptions.Timeout,
            requests.exceptions.RequestException):
        return False


def find_reachable_syncthing_url(primary_url: str, api_key: str) -> Tuple[str, str]:
    """
    Find a reachable Syncthing instance.
    Returns (base_url, source_description).
    Tries: primary URL -> loopback -> local IPs
    """
    # Try primary URL first
    if check_syncthing_reachable(primary_url, api_key):
        return (primary_url, "primary URL")

    # Build fallback URLs in order of preference:
    # 1. Loopback (127.0.0.1, localhost)
    # 2. Local network IPs (auto-detected)
    fallback_urls = [
        "http://127.0.0.1:8384",
        "http://localhost:8384",
    ]

    # Add local IP addresses (e.g., 192.168.x.x, 10.x.x.x)
    local_ips = get_local_ip_addresses()
    for ip in local_ips:
        fallback_urls.append(f"http://{ip}:8384")

    # Try fallback URLs
    for fallback_url in fallback_urls:
        if fallback_url == primary_url:
            continue
        if check_syncthing_reachable(fallback_url, api_key):
            return (fallback_url, f"fallback ({fallback_url})")

    # Nothing reachable
    return (None, None)


def get_client(args, use_fallback: bool = True):
    """
    Get a configured SyncthingClient from args.

    If use_fallback is True (default for CLI mode), will try to find a reachable
    Syncthing instance if the primary URL is not accessible.
    """
    # Get API key
    if hasattr(args, 'api_key') and args.api_key:
        api_key = args.api_key
    elif hasattr(args, 'config_xml') and args.config_xml:
        api_key = get_api_key_from_config(args.config_xml)
    else:
        raise Exception("Either --api-key or --config-xml must be provided")

    base_url = args.base_url

    # For CLI mode, try to find a reachable instance
    if use_fallback and hasattr(args, 'mode') and args.mode == 'cli':
        # Check if primary URL is reachable
        if not check_syncthing_reachable(base_url, api_key):
            print(f"Primary Syncthing URL ({base_url}) is not reachable, trying fallbacks...", file=sys.stderr)

            fallback_url, source = find_reachable_syncthing_url(base_url, api_key)

            if fallback_url:
                print(f"Found reachable Syncthing instance at {source}: {fallback_url}", file=sys.stderr)
                base_url = fallback_url
            else:
                # List what we tried
                error_msg = f"""
Could not connect to Syncthing at any known location:
  - Primary: {base_url}
  - Tried fallbacks: http://127.0.0.1:8384, http://localhost:8384

Please check that:
  1. Syncthing is running
  2. The correct URL is specified with --base-url
  3. You have network connectivity to the Syncthing instance
"""
                print(error_msg, file=sys.stderr)
                raise Exception(f"Syncthing API not reachable at {base_url}")

    return SyncthingClient(base_url, api_key)


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

    print(f"  Syncing devices ({len(devices_config)} configured)...", file=sys.stderr)

    # Add or update devices that are in config
    for device_name, device_id in devices_config.items():
        if device_id in current_devices:
            current_name = current_devices[device_id].get("name", "")
            if current_name != device_name:
                print(f"    UPDATE: {current_name} -> {device_name} ({device_id[:7]}...)", file=sys.stderr)
                if not dry_run:
                    client.update_device(device_id, {"name": device_name})
                    print(f"      ✓ Device name updated", file=sys.stderr)
                else:
                    print(f"      [DRY-RUN] Would update device name", file=sys.stderr)
            else:
                print(f"    OK: {device_name} ({device_id[:7]}...) already configured", file=sys.stderr)
        else:
            print(f"    ADD: {device_name} ({device_id[:7]}...)", file=sys.stderr)
            if not dry_run:
                client.add_device(device_id, device_name)
                print(f"      ✓ Device added", file=sys.stderr)
            else:
                print(f"      [DRY-RUN] Would add device", file=sys.stderr)

    # Remove devices that are in Syncthing but not in config
    for device_id, device in current_devices.items():
        if device_id not in configured_device_ids:
            device_name = device.get("name", "Unknown")
            print(f"    REMOVE: {device_name} ({device_id[:7]}...)", file=sys.stderr)
            if not dry_run:
                client.remove_device(device_id)
                print(f"      ✓ Device removed", file=sys.stderr)
            else:
                print(f"      [DRY-RUN] Would remove device", file=sys.stderr)


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

    print(f"  Syncing folders ({len(folders_config)} configured)...", file=sys.stderr)

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
                print(f"    UPDATE: {folder_id}", file=sys.stderr)
                if not dry_run:
                    # Build device list for API
                    devices_list = [{"deviceID": dev_id} for dev_id in new_devices]
                    update_data = {
                        "label": new_label,
                        "path": new_path,
                        "devices": devices_list,
                    }
                    client.update_folder(folder_id, update_data)
                    print(f"      ✓ Folder updated", file=sys.stderr)
                else:
                    print(f"      [DRY-RUN] Would update folder", file=sys.stderr)
            else:
                print(f"    OK: {folder_id} already configured", file=sys.stderr)
        else:
            print(f"    ADD: {folder_id}", file=sys.stderr)
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
                print(f"      ✓ Folder added", file=sys.stderr)
            else:
                print(f"      [DRY-RUN] Would add folder", file=sys.stderr)

    # Remove folders that are in Syncthing but not in config
    for folder_id, folder in current_folders.items():
        if folder_id not in configured_folder_ids:
            folder_label = folder.get("label", folder_id)
            print(f"    REMOVE: {folder_label} ({folder_id})", file=sys.stderr)
            if not dry_run:
                client.remove_folder(folder_id)
                print(f"      ✓ Folder removed", file=sys.stderr)
            else:
                print(f"      [DRY-RUN] Would remove folder", file=sys.stderr)


def cmd_sync(args):
    """Sync GUI credentials and devices from configuration file."""
    try:
        # Load configuration
        with open(args.config_file, "r") as f:
            config = json.load(f)

        client = get_client(args)

        print("Syncing Syncthing configuration...", file=sys.stderr)

        # Sync GUI credentials if present
        if "gui" in config and config["gui"] is not None:
            gui_config = config["gui"]
            username = gui_config.get("username")
            password = gui_config.get("password")

            if username or password:
                print(f"  Updating GUI credentials...", file=sys.stderr)

                # Hash password if needed
                password_hash = None
                if password:
                    # Check if it's already a bcrypt hash
                    if password.startswith("$2"):
                        password_hash = password
                        print(f"    Using pre-hashed password", file=sys.stderr)
                    else:
                        password_hash = hash_password(password)
                        print(f"    Hashed plain text password with bcrypt", file=sys.stderr)

                if not args.dry_run:
                    client.update_gui_config(username=username, password_hash=password_hash)
                    print(f"    ✓ GUI credentials updated", file=sys.stderr)
                else:
                    print(f"    [DRY-RUN] Would update GUI credentials", file=sys.stderr)

        # Sync devices if present (fully declarative - add and remove)
        if "devices" in config:
            sync_devices(client, config["devices"], dry_run=args.dry_run)

        # Sync folders if present (fully declarative - add and remove)
        if "folders" in config:
            devices_config = config.get("devices", {})
            sync_folders(client, config["folders"], devices_config, dry_run=args.dry_run)

        if args.dry_run:
            print("", file=sys.stderr)
            print("Dry-run complete - no changes made", file=sys.stderr)
        else:
            print("", file=sys.stderr)
            print("Sync complete!", file=sys.stderr)

            if args.restart:
                print("Restarting Syncthing...", file=sys.stderr)
                client.restart_syncthing()
                print("Restart initiated", file=sys.stderr)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        print("\nFull traceback:", file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
        sys.exit(1)


def display_devices(devices, detailed=False):
    """Display devices in a formatted list."""
    if not devices:
        print("  (none)")
        return

    for device in devices:
        if not device or not isinstance(device, dict):
            continue
        name = device.get("name", "Unknown")
        device_id = device.get("deviceID", "")

        if detailed:
            print(f"  • {name}")
            print(f"    ID: {device_id}")
            print()
        else:
            print(f"  • {name} ({device_id[:7]}...)")


def display_folders(folders, detailed=False, device_map=None):
    """
    Display folders in a formatted list.

    Args:
        folders: List of folder configs
        detailed: Show detailed info including folder IDs
        device_map: Dict mapping device IDs to device names (for resolving shared devices)
    """
    if not folders:
        print("  (none)")
        return

    for folder in folders:
        if not folder or not isinstance(folder, dict):
            continue
        folder_id = folder.get("id", "")
        label = folder.get("label", folder_id)
        path = folder.get("path", "")
        devices = folder.get("devices", [])

        if detailed:
            print(f"  • {label}")
            print(f"    ID: {folder_id}")
            print(f"    Path: {path}")
            if devices:
                device_names = [d.get("deviceID", "")[:7] + "..." for d in devices if d and isinstance(d, dict)]
                print(f"    Devices: {', '.join(device_names)}")
            print()
        else:
            print(f"  • {label}")
            print(f"    Path: {path}")
            if devices:
                # Resolve device IDs to names
                device_list = []
                for d in devices:
                    if d and isinstance(d, dict):
                        dev_id = d.get("deviceID", "")
                        if device_map and dev_id in device_map:
                            device_list.append(device_map[dev_id])
                        else:
                            device_list.append(dev_id[:7] + "...")

                if device_list:
                    print(f"    Shared with: {', '.join(device_list)}")


def cmd_list_devices(args):
    """List all configured devices."""
    try:
        client = get_client(args)
        devices = client.get_devices()

        print(f"Configured devices ({len(devices) if devices else 0}):")
        print()
        display_devices(devices, detailed=True)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_list_folders(args):
    """List all configured folders."""
    try:
        client = get_client(args)
        devices = client.get_devices()
        folders = client.get_folders()

        # Build device ID to name map
        device_map = {d.get("deviceID"): d.get("name", "Unknown")
                      for d in devices if d and isinstance(d, dict) and "deviceID" in d}

        print(f"Configured folders ({len(folders) if folders else 0}):")
        print()
        display_folders(folders, detailed=True, device_map=device_map)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_status(args):
    """Show status of configured devices and folders."""
    try:
        client = get_client(args)

        # Get devices and folders
        devices = client.get_devices()
        folders = client.get_folders()

        # Build device ID to name map for folder display
        device_map = {d.get("deviceID"): d.get("name", "Unknown")
                      for d in devices if d and isinstance(d, dict) and "deviceID" in d}

        # Display devices
        print(f"Devices ({len(devices) if devices else 0}):")
        if devices:
            print()
        display_devices(devices, detailed=False)

        print()

        # Display folders with device name resolution
        print(f"Folders ({len(folders) if folders else 0}):")
        if folders:
            print()
        display_folders(folders, detailed=False, device_map=device_map)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
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

    # CLI: list-devices command
    list_devices_parser = cli_subparsers.add_parser(
        "list-devices", help="List all configured devices"
    )
    add_cli_args(list_devices_parser)

    # CLI: list-folders command
    list_folders_parser = cli_subparsers.add_parser(
        "list-folders", help="List all configured folders"
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
        if args.cli_command == "list-devices":
            cmd_list_devices(args)
        elif args.cli_command == "list-folders":
            cmd_list_folders(args)
        elif args.cli_command == "status":
            cmd_status(args)


if __name__ == "__main__":
    main()
