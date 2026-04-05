"""Forgejo API client."""

import requests


class ForgejoClient:
    def __init__(self, base_url: str, token: str, timeout: int = 30):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.headers = {
            "Authorization": f"token {token}",
            "Content-Type": "application/json",
        }

    def _api_call(self, method: str, endpoint: str, data=None):
        url = f"{self.base_url}/api/v1{endpoint}"
        try:
            response = requests.request(
                method=method,
                url=url,
                json=data,
                headers=self.headers,
                timeout=self.timeout,
            )
            if response.status_code == 204:
                return None
            if response.status_code == 409:
                return {"conflict": True}
            if response.status_code not in (200, 201):
                try:
                    error_data = response.json()
                    message = error_data.get("message", "Unknown error")
                except ValueError:
                    message = response.text
                raise Exception(
                    f"API error: {message} (Status: {response.status_code})"
                )
            return response.json()
        except requests.exceptions.RequestException as e:
            raise Exception(f"Network error: {e}")

    def user_exists(self, username: str) -> bool:
        url = f"{self.base_url}/api/v1/users/{username}"
        try:
            response = requests.get(url, headers=self.headers, timeout=self.timeout)
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False

    def create_user(self, username: str, email: str, password: str):
        return self._api_call(
            "POST",
            "/admin/users",
            {
                "username": username,
                "email": email,
                "password": password,
                "must_change_password": False,
                "visibility": "private",
            },
        )

    def repo_exists(self, owner: str, name: str) -> bool:
        url = f"{self.base_url}/api/v1/repos/{owner}/{name}"
        try:
            response = requests.get(url, headers=self.headers, timeout=self.timeout)
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False

    def create_repo_for_user(
        self,
        owner: str,
        name: str,
        description: str = "",
        private: bool = True,
        auto_init: bool = False,
    ):
        return self._api_call(
            "POST",
            f"/admin/users/{owner}/repos",
            {
                "name": name,
                "description": description,
                "private": private,
                "auto_init": auto_init,
            },
        )

    def list_repos(self):
        return self._api_call("GET", "/user/repos")

    def list_gpg_keys(self, username: str):
        return self._api_call("GET", f"/users/{username}/gpg_keys") or []

    def create_gpg_key(self, armored_key: str):
        return self._api_call(
            "POST",
            "/user/gpg_keys",
            {
                "armored_public_key": armored_key,
            },
        )
