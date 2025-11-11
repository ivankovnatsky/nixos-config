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


def cmd_sync(args):
    """Sync GUI credentials and devices from configuration file."""
    try:
        # Load configuration
        with open(args.config_file, "r") as f:
            config = json.load(f)

        # Get API key
        if args.api_key:
            api_key = args.api_key
        elif args.config_xml:
            api_key = get_api_key_from_config(args.config_xml)
        else:
            raise Exception("Either --api-key or --config-xml must be provided")

        client = SyncthingClient(args.base_url, api_key)

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
            devices_config = config["devices"]
            current_devices = {dev["deviceID"]: dev for dev in client.get_devices() if dev and isinstance(dev, dict) and "deviceID" in dev}
            configured_device_ids = set(devices_config.values())

            print(f"  Syncing devices ({len(devices_config)} configured)...", file=sys.stderr)

            # Add or update devices that are in config
            for device_name, device_id in devices_config.items():
                if device_id in current_devices:
                    current_name = current_devices[device_id].get("name", "")
                    if current_name != device_name:
                        print(f"    UPDATE: {current_name} -> {device_name} ({device_id[:7]}...)", file=sys.stderr)
                        if not args.dry_run:
                            client.update_device(device_id, {"name": device_name})
                            print(f"      ✓ Device name updated", file=sys.stderr)
                        else:
                            print(f"      [DRY-RUN] Would update device name", file=sys.stderr)
                    else:
                        print(f"    OK: {device_name} ({device_id[:7]}...) already configured", file=sys.stderr)
                else:
                    print(f"    ADD: {device_name} ({device_id[:7]}...)", file=sys.stderr)
                    if not args.dry_run:
                        client.add_device(device_id, device_name)
                        print(f"      ✓ Device added", file=sys.stderr)
                    else:
                        print(f"      [DRY-RUN] Would add device", file=sys.stderr)

            # Remove devices that are in Syncthing but not in config
            for device_id, device in current_devices.items():
                if device_id not in configured_device_ids:
                    device_name = device.get("name", "Unknown")
                    print(f"    REMOVE: {device_name} ({device_id[:7]}...)", file=sys.stderr)
                    if not args.dry_run:
                        client.remove_device(device_id)
                        print(f"      ✓ Device removed", file=sys.stderr)
                    else:
                        print(f"      [DRY-RUN] Would remove device", file=sys.stderr)

        # Sync folders if present (fully declarative - add and remove)
        if "folders" in config:
            folders_config = config["folders"]
            current_folders = {f["id"]: f for f in client.get_folders() if f and isinstance(f, dict) and "id" in f}
            configured_folder_ids = set(folders_config.keys())

            # Build device name to ID mapping for resolving device references
            devices_config = config.get("devices", {})
            device_name_to_id = {name: dev_id for name, dev_id in devices_config.items()}
            device_id_to_name = {dev_id: name for name, dev_id in devices_config.items()}

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
                    current_devices = set(d.get("deviceID") for d in current_folder.get("devices", []) if d and isinstance(d, dict))

                    new_label = folder_cfg.get("label", folder_id)
                    new_path = folder_cfg["path"]
                    new_devices = set(resolved_device_ids)

                    # Check if anything changed
                    if current_label != new_label or current_path != new_path or current_devices != new_devices:
                        print(f"    UPDATE: {folder_id}", file=sys.stderr)
                        if not args.dry_run:
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
                    if not args.dry_run:
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
                    if not args.dry_run:
                        client.remove_folder(folder_id)
                        print(f"      ✓ Folder removed", file=sys.stderr)
                    else:
                        print(f"      [DRY-RUN] Would remove folder", file=sys.stderr)

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


def main():
    parser = argparse.ArgumentParser(
        description="Syncthing configuration management tool"
    )

    subparsers = parser.add_subparsers(
        dest="command", required=True, help="Command to execute"
    )

    # Sync command
    sync_parser = subparsers.add_parser(
        "sync", help="Sync GUI credentials and devices from configuration file"
    )
    sync_parser.add_argument("--base-url", required=True, help="Syncthing URL")
    sync_parser.add_argument("--api-key", help="Syncthing API key")
    sync_parser.add_argument("--config-xml", help="Path to Syncthing config.xml (to extract API key)")
    sync_parser.add_argument(
        "--config-file", required=True, help="JSON configuration file"
    )
    sync_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without making changes",
    )
    sync_parser.add_argument(
        "--restart",
        action="store_true",
        help="Restart Syncthing after applying changes",
    )

    args = parser.parse_args()

    if args.command == "sync":
        cmd_sync(args)


if __name__ == "__main__":
    main()
