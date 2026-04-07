"""API clients for *arr services (Radarr, Sonarr, Lidarr, Prowlarr)."""

import click
import requests

USER_AGENT = "arr-mgmt/1.0.0"


class ArrClient:
    """Client for Radarr/Sonarr/Lidarr API."""

    def __init__(
        self, base_url: str, api_key: str, timeout: int = 120, api_version: int = 3
    ):
        self.base_url = base_url.rstrip("/")
        self.api_version = api_version
        self.timeout = timeout
        self.headers = {
            "User-Agent": USER_AGENT,
            "X-Api-Key": api_key,
        }

    def _api_call(self, method: str, endpoint: str, data=None):
        """Make API request with error handling."""
        url = f"{self.base_url}{endpoint}"
        try:
            response = requests.request(
                method, url, json=data, headers=self.headers, timeout=self.timeout
            )

            if response.status_code == 429:
                raise Exception("API rate limit exceeded. Please wait before retrying.")

            if response.status_code == 204:
                return None

            if response.status_code not in (200, 201, 202):
                try:
                    error_data = response.json()
                    click.echo(f"DEBUG: Error response: {error_data}", err=True)
                    # Handle both dict and list error responses
                    if isinstance(error_data, list) and len(error_data) > 0:
                        message = error_data[0].get("errorMessage", "Unknown error")
                    elif isinstance(error_data, dict):
                        message = error_data.get("error", "Unknown error")
                    else:
                        message = "Unknown error"
                    raise Exception(
                        f"API error: {message} (Status: {response.status_code})"
                    )
                except (ValueError, requests.exceptions.JSONDecodeError):
                    click.echo(f"DEBUG: Response text: {response.text}", err=True)
                    raise Exception(
                        f"API request failed with status {response.status_code}"
                    )

            try:
                return response.json()
            except (ValueError, requests.exceptions.JSONDecodeError) as e:
                click.echo(f"DEBUG: Failed to parse JSON response from {url}", err=True)
                click.echo(f"DEBUG: Response status: {response.status_code}", err=True)
                click.echo(f"DEBUG: Response text: {response.text[:200]}", err=True)
                raise Exception(f"Invalid JSON response: {e}")
        except requests.exceptions.RequestException as e:
            raise Exception(f"Network error: {e}")

    def list_downloadclients(self):
        """List all download clients."""
        return self._api_call("GET", f"/api/v{self.api_version}/downloadclient")

    def create_downloadclient(self, data):
        """Create a new download client."""
        return self._api_call(
            "POST", f"/api/v{self.api_version}/downloadclient", data=data
        )

    def update_downloadclient(self, client_id: int, data):
        """Update an existing download client."""
        return self._api_call(
            "PUT", f"/api/v{self.api_version}/downloadclient/{client_id}", data=data
        )

    def delete_downloadclient(self, client_id: int):
        """Delete a download client."""
        return self._api_call(
            "DELETE", f"/api/v{self.api_version}/downloadclient/{client_id}"
        )

    def list_rootfolders(self):
        """List all root folders."""
        return self._api_call("GET", f"/api/v{self.api_version}/rootfolder")

    def create_rootfolder(self, path: str, **kwargs):
        """Create a new root folder."""
        data = {"path": path, **kwargs}
        return self._api_call("POST", f"/api/v{self.api_version}/rootfolder", data=data)

    def delete_rootfolder(self, folder_id: int):
        """Delete a root folder."""
        return self._api_call(
            "DELETE", f"/api/v{self.api_version}/rootfolder/{folder_id}"
        )

    def list_qualityprofiles(self):
        """List all quality profiles."""
        return self._api_call("GET", f"/api/v{self.api_version}/qualityprofile")

    def list_metadataprofiles(self):
        """List all metadata profiles (Lidarr only)."""
        return self._api_call("GET", f"/api/v{self.api_version}/metadataprofile")

    def get_host_config(self):
        """Get current host configuration."""
        return self._api_call("GET", f"/api/v{self.api_version}/config/host")

    def update_host_config(self, data):
        """Update host configuration (includes bind address)."""
        return self._api_call("PUT", f"/api/v{self.api_version}/config/host", data=data)


class ProwlarrClient:
    """Client for Prowlarr v1 API."""

    def __init__(self, base_url: str, api_key: str, timeout: int = 120):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.headers = {
            "User-Agent": USER_AGENT,
            "X-Api-Key": api_key,
        }

    def _api_call(self, method: str, endpoint: str, data=None):
        """Make API request with error handling."""
        url = f"{self.base_url}{endpoint}"
        try:
            response = requests.request(
                method, url, json=data, headers=self.headers, timeout=self.timeout
            )

            if response.status_code == 429:
                raise Exception("API rate limit exceeded. Please wait before retrying.")

            if response.status_code == 204:
                return None

            if response.status_code not in (200, 201, 202):
                try:
                    error_data = response.json()
                    click.echo(f"DEBUG: Error response: {error_data}", err=True)
                    # Handle both dict and list error responses
                    if isinstance(error_data, list) and len(error_data) > 0:
                        message = error_data[0].get("errorMessage", "Unknown error")
                    elif isinstance(error_data, dict):
                        message = error_data.get("error", "Unknown error")
                    else:
                        message = "Unknown error"
                    raise Exception(
                        f"API error: {message} (Status: {response.status_code})"
                    )
                except (ValueError, requests.exceptions.JSONDecodeError):
                    click.echo(f"DEBUG: Response text: {response.text}", err=True)
                    raise Exception(
                        f"API request failed with status {response.status_code}"
                    )

            try:
                return response.json()
            except (ValueError, requests.exceptions.JSONDecodeError) as e:
                click.echo(f"DEBUG: Failed to parse JSON response from {url}", err=True)
                click.echo(f"DEBUG: Response status: {response.status_code}", err=True)
                click.echo(f"DEBUG: Response text: {response.text[:200]}", err=True)
                raise Exception(f"Invalid JSON response: {e}")
        except requests.exceptions.RequestException as e:
            raise Exception(f"Network error: {e}")

    def list_applications(self):
        """List all applications."""
        return self._api_call("GET", "/api/v1/applications")

    def create_application(self, data):
        """Create a new application."""
        return self._api_call("POST", "/api/v1/applications", data=data)

    def update_application(self, app_id: int, data):
        """Update an existing application."""
        return self._api_call("PUT", f"/api/v1/applications/{app_id}", data=data)

    def delete_application(self, app_id: int):
        """Delete an application."""
        return self._api_call("DELETE", f"/api/v1/applications/{app_id}")

    def list_indexers(self):
        """List all indexers."""
        return self._api_call("GET", "/api/v1/indexer")

    def create_indexer(self, data):
        """Create a new indexer."""
        return self._api_call("POST", "/api/v1/indexer", data=data)

    def update_indexer(self, indexer_id: int, data):
        """Update an existing indexer."""
        return self._api_call("PUT", f"/api/v1/indexer/{indexer_id}", data=data)

    def delete_indexer(self, indexer_id: int):
        """Delete an indexer."""
        return self._api_call("DELETE", f"/api/v1/indexer/{indexer_id}")

    def get_host_config(self):
        """Get current host configuration."""
        return self._api_call("GET", "/api/v1/config/host")

    def update_host_config(self, data):
        """Update host configuration (includes bind address)."""
        return self._api_call("PUT", "/api/v1/config/host", data=data)
