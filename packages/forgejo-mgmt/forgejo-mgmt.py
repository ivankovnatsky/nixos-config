#!/usr/bin/env python3
"""
Forgejo management tool.
Declarative user and repository configuration via sync command.
"""

import os
import sys
import json
import subprocess
import time
import argparse
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
            response = requests.get(
                url, headers=self.headers, timeout=self.timeout
            )
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False

    def create_user(self, username: str, email: str, password: str):
        return self._api_call("POST", "/admin/users", {
            "username": username,
            "email": email,
            "password": password,
            "must_change_password": False,
            "visibility": "private",
        })

    def repo_exists(self, owner: str, name: str) -> bool:
        url = f"{self.base_url}/api/v1/repos/{owner}/{name}"
        try:
            response = requests.get(
                url, headers=self.headers, timeout=self.timeout
            )
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False

    def create_repo_for_user(self, owner: str, name: str, description: str = "", private: bool = True, auto_init: bool = False):
        return self._api_call("POST", f"/admin/users/{owner}/repos", {
            "name": name,
            "description": description,
            "private": private,
            "auto_init": auto_init,
        })

    def list_repos(self):
        return self._api_call("GET", "/user/repos")

    def list_gpg_keys(self, username: str):
        return self._api_call("GET", f"/users/{username}/gpg_keys") or []

    def create_gpg_key(self, armored_key: str):
        return self._api_call("POST", "/user/gpg_keys", {
            "armored_public_key": armored_key,
        })


def wait_for_api(base_url: str, max_retries: int = 30, delay: int = 2):
    print(f"Waiting for Forgejo API at {base_url}...", file=sys.stderr)
    for i in range(1, max_retries + 1):
        try:
            response = requests.get(
                f"{base_url}/api/v1/settings/api", timeout=5
            )
            if response.status_code == 200:
                print(f"Forgejo API is ready (attempt {i}/{max_retries})", file=sys.stderr)
                return
        except requests.exceptions.RequestException:
            pass
        if i == max_retries:
            print(f"ERROR: Forgejo API not ready after {max_retries} attempts", file=sys.stderr)
            sys.exit(1)
        print(f"Waiting... (attempt {i}/{max_retries})", file=sys.stderr)
        time.sleep(delay)


def read_file(path: str) -> str:
    with open(path) as f:
        return f.read().strip()


def ensure_admin_user(
    forgejo_bin: str,
    config_file: str,
    work_path: str,
    username: str,
    email: str,
    password: str,
):
    """Create the first admin user via CLI (works without API auth)."""
    result = subprocess.run(
        [forgejo_bin, "admin", "user", "list",
         "--config", config_file, "--work-path", work_path],
        capture_output=True, text=True,
    )
    lines = [l for l in result.stdout.strip().split("\n") if l and not l.startswith("ID")]
    if lines:
        print(f"Users already exist ({len(lines)} found), skipping admin user creation", file=sys.stderr)
        return

    print(f"Creating admin user: {username}", file=sys.stderr)
    result = subprocess.run(
        [forgejo_bin, "admin", "user", "create",
         "--config", config_file, "--work-path", work_path,
         "--username", username,
         "--email", email,
         "--password", password,
         "--admin",
         "--must-change-password=false"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        print(f"ERROR: Failed to create admin user: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print("Admin user created", file=sys.stderr)


def ensure_token(
    base_url: str,
    username: str,
    password: str,
    token_file: str,
) -> str:
    if token_file:
        try:
            token = read_file(token_file)
            if token:
                try:
                    response = requests.get(
                        f"{base_url}/api/v1/user",
                        headers={"Authorization": f"token {token}"},
                        timeout=10,
                    )
                    if response.status_code == 200:
                        print("Using existing API token", file=sys.stderr)
                        return token
                except requests.exceptions.RequestException:
                    pass
                print("Stored token is invalid, regenerating...", file=sys.stderr)
        except FileNotFoundError:
            pass

    print("Creating API token...", file=sys.stderr)
    response = requests.post(
        f"{base_url}/api/v1/users/{username}/tokens",
        auth=(username, password),
        json={"name": "forgejo-mgmt", "scopes": ["all"]},
        timeout=10,
    )
    if response.status_code not in (200, 201):
        print(f"ERROR: Failed to create API token: {response.text}", file=sys.stderr)
        sys.exit(1)

    token = response.json().get("sha1")
    if not token:
        print(f"ERROR: No token in response: {response.text}", file=sys.stderr)
        sys.exit(1)

    if token_file:
        with open(token_file, "w") as f:
            f.write(token)
        os.chmod(token_file, 0o600)

    print("API token created", file=sys.stderr)
    return token


def create_user_token(base_url: str, username: str, password: str, token_name: str = "forgejo-mgmt") -> str:
    """Create an access token for a user using basic auth."""
    response = requests.post(
        f"{base_url}/api/v1/users/{username}/tokens",
        auth=(username, password),
        json={"name": token_name, "scopes": ["all"]},
        timeout=10,
    )
    if response.status_code == 422:
        print(f"  Token '{token_name}' already exists for {username}", file=sys.stderr)
        return ""
    if response.status_code not in (200, 201):
        print(f"  WARNING: Failed to create token for {username}: {response.text}", file=sys.stderr)
        return ""
    return response.json().get("sha1", "")


def upload_gpg_key(base_url: str, username: str, password: str, armored_key: str):
    """Upload a GPG public key for a user using basic auth."""
    # Check if user already has GPG keys
    try:
        response = requests.get(
            f"{base_url}/api/v1/users/{username}/gpg_keys",
            timeout=10,
        )
        if response.status_code == 200:
            existing_keys = response.json()
            if existing_keys:
                print(f"  GPG key already exists for {username} ({len(existing_keys)} key(s)), skipping", file=sys.stderr)
                return
    except requests.exceptions.RequestException:
        pass

    print(f"  Uploading GPG key for {username}...", file=sys.stderr)
    response = requests.post(
        f"{base_url}/api/v1/user/gpg_keys",
        auth=(username, password),
        json={"armored_public_key": armored_key},
        timeout=10,
    )
    if response.status_code in (200, 201):
        key_data = response.json()
        key_id = key_data.get("primary_key_id") or key_data.get("key_id", "unknown")
        print(f"  GPG key uploaded for {username} (key ID: {key_id})", file=sys.stderr)
    elif response.status_code == 422:
        print(f"  GPG key rejected (422) for {username}: {response.text}", file=sys.stderr)
    else:
        print(f"  WARNING: Failed to upload GPG key for {username}: {response.text}", file=sys.stderr)


def sync_users(client: ForgejoClient, users: list, base_url: str):
    print("", file=sys.stderr)
    print("=== User Sync ===", file=sys.stderr)
    for user in users:
        username = user["username"]
        if user.get("admin"):
            print(f"  OK: {username} (admin, created via CLI)", file=sys.stderr)
            continue
        if client.user_exists(username):
            print(f"  OK: {username} (exists)", file=sys.stderr)
        else:
            email = read_file(user["emailFile"])
            password = read_file(user["passwordFile"])
            print(f"  CREATE: {username}", file=sys.stderr)
            client.create_user(username, email, password)
            print(f"  Created: {username}", file=sys.stderr)

        if user.get("createToken"):
            password = read_file(user["passwordFile"])
            token = create_user_token(base_url, username, password)
            if token:
                print(f"  TOKEN for {username}: {token}", file=sys.stderr)
                print(f"  Save this token to sops — it will not be shown again", file=sys.stderr)

        gpg_key_file = user.get("gpgKeyFile")
        if gpg_key_file:
            password = read_file(user["passwordFile"])
            armored_key = read_file(gpg_key_file)
            upload_gpg_key(base_url, username, password, armored_key)


def sync_repos(client: ForgejoClient, repos: list):
    print("", file=sys.stderr)
    print("=== Repository Sync ===", file=sys.stderr)
    for repo in repos:
        name = repo["name"]
        owner = repo["owner"]
        if client.repo_exists(owner, name):
            print(f"  OK: {owner}/{name} (exists)", file=sys.stderr)
        else:
            print(f"  CREATE: {owner}/{name}", file=sys.stderr)
            client.create_repo_for_user(
                owner=owner,
                name=name,
                description=repo.get("description", ""),
                private=repo.get("private", True),
                auto_init=repo.get("autoInit", False),
            )
            print(f"  Created: {owner}/{name}", file=sys.stderr)
    print("", file=sys.stderr)
    print("Repository sync complete!", file=sys.stderr)


def cmd_sync(args):
    with open(args.config_file) as f:
        config = json.load(f)

    base_url = config["baseUrl"]
    forgejo_bin = config["forgejoBin"]
    config_path = config["configFile"]
    work_path = config["workPath"]
    token_file = config.get("tokenFile", "")
    users = config.get("users", [])

    # Find the admin user
    admin = next((u for u in users if u.get("admin")), None)
    if not admin:
        print("ERROR: No admin user defined", file=sys.stderr)
        sys.exit(1)

    admin_username = admin["username"]
    admin_email = read_file(admin["emailFile"])
    admin_password = read_file(admin["passwordFile"])

    wait_for_api(base_url)
    ensure_admin_user(forgejo_bin, config_path, work_path, admin_username, admin_email, admin_password)
    token = ensure_token(base_url, admin_username, admin_password, token_file)

    client = ForgejoClient(base_url, token)

    # Create non-admin users via API
    non_admin_users = [u for u in users if not u.get("admin")]
    if non_admin_users:
        sync_users(client, non_admin_users, base_url)

    repos = config.get("repositories", [])
    if repos:
        sync_repos(client, repos)

    print("Forgejo management completed", file=sys.stderr)


def cmd_list(args):
    with open(args.config_file) as f:
        config = json.load(f)

    token_file = config.get("tokenFile", "")
    try:
        token = read_file(token_file)
    except FileNotFoundError:
        print("ERROR: No token file found. Run sync first.", file=sys.stderr)
        sys.exit(1)

    client = ForgejoClient(config["baseUrl"], token)
    repos = client.list_repos()
    if args.output_format == "json":
        print(json.dumps(repos, indent=2))
    else:
        print("Repositories:")
        for repo in repos:
            visibility = "private" if repo.get("private") else "public"
            print(f"  {repo['full_name']} ({visibility})")


def main():
    parser = argparse.ArgumentParser(description="Forgejo management tool")
    subparsers = parser.add_subparsers(dest="command", required=True)

    sync_parser = subparsers.add_parser("sync", help="Sync users and repositories")
    sync_parser.add_argument("--config-file", required=True, help="JSON configuration file")

    list_parser = subparsers.add_parser("list", help="List repositories")
    list_parser.add_argument("--config-file", required=True, help="JSON configuration file")
    list_parser.add_argument("--output-format", choices=["table", "json"], default="table")

    args = parser.parse_args()

    if args.command == "sync":
        cmd_sync(args)
    elif args.command == "list":
        cmd_list(args)


if __name__ == "__main__":
    main()
