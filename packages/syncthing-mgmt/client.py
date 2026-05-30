"""Syncthing REST API client."""

import time
import logging
import requests

USER_AGENT = "syncthing-mgmt/1.0.0"


class SyncthingClient:
    def __init__(
        self,
        base_url: str,
        api_key: str,
        timeout: int = 30,
        max_retries: int = 5,
        retry_delay: float = 2.0,
    ):
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
                    wait_time = self.retry_delay * (2**attempt)  # Exponential backoff
                    logging.info(
                        f"    Connection error, retrying in {wait_time:.1f}s... (attempt {attempt + 1}/{self.max_retries})"
                    )
                    time.sleep(wait_time)
                    continue
                raise Exception(
                    f"Network error after {self.max_retries} attempts: {last_error}"
                )

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
        return self._api_call(
            "PATCH", f"/rest/config/devices/{device_id}", data=device_config
        )

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
        return self._api_call(
            "PATCH", f"/rest/config/folders/{folder_id}", data=folder_config
        )

    def add_folder(self, folder_id: str, folder_config: dict):
        """Add a new folder."""
        return self._api_call(
            "PUT", f"/rest/config/folders/{folder_id}", data=folder_config
        )

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

    def scan_folder(self, folder_id: str):
        """Trigger a rescan for a folder."""
        return self._api_call("POST", f"/rest/db/scan?folder={folder_id}")

    def get_folder_ignores(self, folder_id: str):
        """Get ignore patterns for a folder."""
        return self._api_call("GET", f"/rest/db/ignores?folder={folder_id}")

    def set_folder_ignores(self, folder_id: str, patterns: list):
        """Set ignore patterns for a folder."""
        return self._api_call(
            "POST", f"/rest/db/ignores?folder={folder_id}", data={"ignore": patterns}
        )

    def get_system_status(self):
        """Get system status (includes local device ID)."""
        return self._api_call("GET", "/rest/system/status")

    def get_options(self):
        """Get Syncthing options configuration."""
        return self._api_call("GET", "/rest/config/options")

    def update_options(self, options: dict):
        """Update Syncthing options configuration."""
        return self._api_call("PATCH", "/rest/config/options", data=options)
