"""Jellyfin API client."""

import sys
import requests

USER_AGENT = "jellyfin-mgmt/1.0.0"


class JellyfinClient:
    def __init__(self, base_url: str, api_key: str, timeout: int = 120):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.headers = {
            "User-Agent": USER_AGENT,
            "X-Emby-Token": api_key,
        }

    def _api_call(self, method: str, endpoint: str, data=None, params=None):
        """Make API request with error handling."""
        url = f"{self.base_url}{endpoint}"
        try:
            # Only include json parameter if data is not None
            # This prevents Content-Type: application/json header when we only want query params
            request_kwargs = {
                "method": method,
                "url": url,
                "params": params,
                "headers": self.headers,
                "timeout": self.timeout,
            }
            if data is not None:
                request_kwargs["json"] = data

            response = requests.request(**request_kwargs)

            if response.status_code == 429:
                raise Exception("API rate limit exceeded. Please wait before retrying.")

            if response.status_code == 204:
                return None

            if response.status_code not in (200, 201):
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

            return response.json()
        except requests.exceptions.RequestException as e:
            raise Exception(f"Network error: {e}")

    def list_libraries(self):
        """List all virtual folders (libraries)."""
        data = self._api_call("GET", "/Library/VirtualFolders")
        return data if data else []

    def create_library(
        self,
        name: str,
        paths: list,
        collection_type: str = "movies",
        refresh: bool = True,
    ):
        """Create a new virtual folder (library)."""
        params = {
            "name": name,
            "collectionType": collection_type,
            "paths": paths,
            "refreshLibrary": refresh,
        }
        return self._api_call("POST", "/Library/VirtualFolders", params=params)

    def remove_media_path(self, name: str, path: str):
        """Remove a single media path from a library."""
        params = {"name": name, "path": path}
        return self._api_call("DELETE", "/Library/VirtualFolders/Paths", params=params)

    def add_media_path(self, name: str, path: str, refresh: bool = True):
        """Add a single media path to a library."""
        data = {
            "Name": name,
            "Path": path,
        }
        params = {"refreshLibrary": refresh}
        return self._api_call(
            "POST", "/Library/VirtualFolders/Paths", data=data, params=params
        )

    def update_library_paths(self, name: str, current_paths: list, desired_paths: list):
        """Update library paths by removing old and adding new paths.

        Args:
            name: Library name
            current_paths: List of current paths in the library
            desired_paths: List of desired paths
        """
        # Remove paths that are no longer needed
        paths_to_remove = set(current_paths) - set(desired_paths)
        for path in paths_to_remove:
            self.remove_media_path(name, path)

        # Add new paths
        paths_to_add = set(desired_paths) - set(current_paths)
        for i, path in enumerate(paths_to_add):
            # Only refresh on the last path
            refresh = i == len(paths_to_add) - 1
            self.add_media_path(name, path, refresh=refresh)

    def delete_library(self, name: str):
        """Delete a library."""
        params = {"name": name}
        return self._api_call("DELETE", "/Library/VirtualFolders", params=params)

    def get_network_config(self):
        """Get current network configuration."""
        # Jellyfin stores network configuration separately
        config = self._api_call("GET", "/System/Configuration/network")
        # Extract only network-related fields
        return {
            "LocalNetworkAddresses": config.get("LocalNetworkAddresses", []),
            "InternalHttpPort": config.get("InternalHttpPort", 8096),
            "PublicHttpPort": config.get("PublicHttpPort", 8096),
        }

    def update_network_config(self, local_network_addresses: list):
        """Update network configuration (bind addresses)."""
        # Get current network configuration (stored separately from main config)
        current_network_config = self._api_call("GET", "/System/Configuration/network")

        # Update only the LocalNetworkAddresses field
        current_network_config["LocalNetworkAddresses"] = local_network_addresses

        # POST the network configuration back to the network endpoint
        return self._api_call(
            "POST", "/System/Configuration/network", data=current_network_config
        )

    def get_library_id(self, name: str):
        """Get library ID by name."""
        libraries = self.list_libraries()
        for lib in libraries:
            if lib.get("Name") == name:
                return lib.get("ItemId")
        return None

    def get_library_options(self, library_id: str):
        """Get current library options for a library."""
        libraries = self.list_libraries()
        for lib in libraries:
            if lib.get("ItemId") == library_id:
                return lib.get("LibraryOptions", {})
        return {}

    def update_library_options(self, library_id: str, library_options: dict):
        """Update library options for a specific library."""
        data = {"Id": library_id, "LibraryOptions": library_options}
        return self._api_call(
            "POST", "/Library/VirtualFolders/LibraryOptions", data=data
        )
