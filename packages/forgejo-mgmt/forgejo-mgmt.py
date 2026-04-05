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

import click
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


def wait_for_api(base_url: str, max_retries: int = 30, delay: int = 2):
    click.echo(f"Waiting for Forgejo API at {base_url}...", err=True)
    for i in range(1, max_retries + 1):
        try:
            response = requests.get(f"{base_url}/api/v1/settings/api", timeout=5)
            if response.status_code == 200:
                click.echo(
                    f"Forgejo API is ready (attempt {i}/{max_retries})", err=True
                )
                return
        except requests.exceptions.RequestException:
            pass
        if i == max_retries:
            click.echo(
                f"ERROR: Forgejo API not ready after {max_retries} attempts",
                err=True,
            )
            sys.exit(1)
        click.echo(f"Waiting... (attempt {i}/{max_retries})", err=True)
        time.sleep(delay)


def read_file(path: str) -> str:
    with open(path) as f:
        return f.read().strip()


def resolve_username(user: dict) -> str:
    """Resolve username from usernameFile or username field."""
    if user.get("usernameFile"):
        return read_file(user["usernameFile"])
    return user["username"]


def resolve_owner(repo: dict) -> str:
    """Resolve owner from ownerFile or owner field."""
    if repo.get("ownerFile"):
        return read_file(repo["ownerFile"])
    return repo["owner"]


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
        [
            forgejo_bin,
            "admin",
            "user",
            "list",
            "--config",
            config_file,
            "--work-path",
            work_path,
        ],
        capture_output=True,
        text=True,
    )
    lines = [
        line
        for line in result.stdout.strip().split("\n")
        if line and not line.startswith("ID")
    ]
    if lines:
        click.echo(
            f"Users already exist ({len(lines)} found), skipping admin user creation",
            err=True,
        )
        return

    click.echo(f"Creating admin user: {username}", err=True)
    result = subprocess.run(
        [
            forgejo_bin,
            "admin",
            "user",
            "create",
            "--config",
            config_file,
            "--work-path",
            work_path,
            "--username",
            username,
            "--email",
            email,
            "--password",
            password,
            "--admin",
            "--must-change-password=false",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        click.echo(f"ERROR: Failed to create admin user: {result.stderr}", err=True)
        sys.exit(1)
    click.echo("Admin user created", err=True)


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
                        click.echo("Using existing API token", err=True)
                        return token
                except requests.exceptions.RequestException:
                    pass
                click.echo("Stored token is invalid, regenerating...", err=True)
        except FileNotFoundError:
            pass

    click.echo("Creating API token...", err=True)
    response = requests.post(
        f"{base_url}/api/v1/users/{username}/tokens",
        auth=(username, password),
        json={"name": "forgejo-mgmt", "scopes": ["all"]},
        timeout=10,
    )
    if response.status_code not in (200, 201):
        click.echo(f"ERROR: Failed to create API token: {response.text}", err=True)
        sys.exit(1)

    token = response.json().get("sha1")
    if not token:
        click.echo(f"ERROR: No token in response: {response.text}", err=True)
        sys.exit(1)

    if token_file:
        with open(token_file, "w") as f:
            f.write(token)
        os.chmod(token_file, 0o600)

    click.echo("API token created", err=True)
    return token


def create_user_token(
    base_url: str, username: str, password: str, token_name: str = "forgejo-mgmt"
) -> str:
    """Create an access token for a user using basic auth."""
    response = requests.post(
        f"{base_url}/api/v1/users/{username}/tokens",
        auth=(username, password),
        json={"name": token_name, "scopes": ["all"]},
        timeout=10,
    )
    if response.status_code not in (200, 201):
        if "has been used already" in response.text:
            click.echo(f"  Token already exists for {username}, skipping", err=True)
        else:
            click.echo(
                f"  ERROR: Failed to create token for {username} (HTTP {response.status_code}): {response.text}",
                err=True,
            )
        return ""
    return response.json().get("sha1", "")


def get_key_id_from_armored(armored_key: str) -> str:
    """Extract the primary key ID from an armored GPG public key using gpg."""
    try:
        result = subprocess.run(
            ["gpg", "--with-colons", "--import-options", "show-only", "--import"],
            input=armored_key,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        return ""
    if result.returncode != 0:
        return ""
    for line in result.stdout.splitlines():
        fields = line.split(":")
        if fields[0] == "pub" and len(fields) > 4:
            return fields[4]  # long key ID
    return ""


def upload_gpg_key(base_url: str, username: str, password: str, armored_key: str):
    """Upload a GPG public key for a user using basic auth."""
    wanted_key_id = get_key_id_from_armored(armored_key)

    # Check existing GPG keys using authenticated endpoint
    try:
        response = requests.get(
            f"{base_url}/api/v1/user/gpg_keys",
            auth=(username, password),
            timeout=10,
        )
        if response.status_code == 200:
            existing_keys = response.json()
            for key in existing_keys:
                existing_id = key.get("primary_key_id") or key.get("key_id", "")
                if (
                    wanted_key_id
                    and len(wanted_key_id) >= 16
                    and existing_id
                    and existing_id.endswith(wanted_key_id[-16:])
                ):
                    click.echo(
                        f"  GPG key already exists for {username} (key ID: {existing_id}), skipping",
                        err=True,
                    )
                    return
            if not wanted_key_id and existing_keys:
                click.echo(
                    f"  GPG key already exists for {username} ({len(existing_keys)} key(s)), skipping",
                    err=True,
                )
                return
    except requests.exceptions.RequestException as e:
        click.echo(
            f"  WARNING: Could not check existing GPG keys for {username}: {e}",
            err=True,
        )

    click.echo(f"  Uploading GPG key for {username}...", err=True)
    response = requests.post(
        f"{base_url}/api/v1/user/gpg_keys",
        auth=(username, password),
        json={"armored_public_key": armored_key},
        timeout=10,
    )
    if response.status_code in (200, 201):
        key_data = response.json()
        key_id = key_data.get("primary_key_id") or key_data.get("key_id", "unknown")
        click.echo(f"  GPG key uploaded for {username} (key ID: {key_id})", err=True)
    elif response.status_code == 422:
        click.echo(
            f"  GPG key already exists for {username} (server rejected duplicate): {response.text}",
            err=True,
        )
    else:
        click.echo(
            f"  WARNING: Failed to upload GPG key for {username}: {response.text}",
            err=True,
        )


def sync_users(client: ForgejoClient, users: list, base_url: str):
    click.echo("", err=True)
    click.echo("=== User Sync ===", err=True)
    for user in users:
        username = resolve_username(user)
        if user.get("admin"):
            click.echo(f"  OK: {username} (admin, created via CLI)", err=True)
            continue
        if client.user_exists(username):
            click.echo(f"  OK: {username} (exists)", err=True)
        else:
            email = read_file(user["emailFile"])
            password = read_file(user["passwordFile"])
            click.echo(f"  CREATE: {username}", err=True)
            client.create_user(username, email, password)
            click.echo(f"  Created: {username}", err=True)

        if user.get("createToken"):
            password = read_file(user["passwordFile"])
            token = create_user_token(base_url, username, password)
            if token:
                click.echo(f"  TOKEN for {username}: {token}", err=True)
                click.echo(
                    "  Save this token to sops — it will not be shown again",
                    err=True,
                )

        gpg_key_file = user.get("gpgKeyFile")
        if gpg_key_file:
            password = read_file(user["passwordFile"])
            armored_key = read_file(gpg_key_file)
            upload_gpg_key(base_url, username, password, armored_key)


def sync_repos(client: ForgejoClient, repos: list):
    click.echo("", err=True)
    click.echo("=== Repository Sync ===", err=True)
    for repo in repos:
        name = repo["name"]
        owner = resolve_owner(repo)
        if client.repo_exists(owner, name):
            click.echo(f"  OK: {owner}/{name} (exists)", err=True)
        else:
            click.echo(f"  CREATE: {owner}/{name}", err=True)
            client.create_repo_for_user(
                owner=owner,
                name=name,
                description=repo.get("description", ""),
                private=repo.get("private", True),
                auto_init=repo.get("autoInit", False),
            )
            click.echo(f"  Created: {owner}/{name}", err=True)
    click.echo("", err=True)
    click.echo("Repository sync complete!", err=True)


@click.group()
def cli():
    """Forgejo management tool."""


@cli.command()
@click.option(
    "--config-file",
    required=True,
    help="JSON configuration file",
)
def sync(config_file):
    """Sync users and repositories."""
    with open(config_file) as f:
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
        click.echo("ERROR: No admin user defined", err=True)
        sys.exit(1)

    admin_username = resolve_username(admin)
    admin_email = read_file(admin["emailFile"])
    admin_password = read_file(admin["passwordFile"])

    wait_for_api(base_url)
    ensure_admin_user(
        forgejo_bin, config_path, work_path, admin_username, admin_email, admin_password
    )
    token = ensure_token(base_url, admin_username, admin_password, token_file)

    client = ForgejoClient(base_url, token)

    # Create non-admin users via API
    non_admin_users = [u for u in users if not u.get("admin")]
    if non_admin_users:
        sync_users(client, non_admin_users, base_url)

    repos = config.get("repositories", [])
    if repos:
        sync_repos(client, repos)

    click.echo("Forgejo management completed", err=True)


@cli.command("list")
@click.option(
    "--config-file",
    required=True,
    help="JSON configuration file",
)
@click.option(
    "--output-format",
    type=click.Choice(["table", "json"]),
    default="table",
)
def list_cmd(config_file, output_format):
    """List repositories."""
    with open(config_file) as f:
        config = json.load(f)

    token_file = config.get("tokenFile", "")
    try:
        token = read_file(token_file)
    except FileNotFoundError:
        click.echo("ERROR: No token file found. Run sync first.", err=True)
        sys.exit(1)

    client = ForgejoClient(config["baseUrl"], token)
    repos = client.list_repos()
    if output_format == "json":
        click.echo(json.dumps(repos, indent=2))
    else:
        click.echo("Repositories:")
        for repo in repos:
            visibility = "private" if repo.get("private") else "public"
            click.echo(f"  {repo['full_name']} ({visibility})")


if __name__ == "__main__":
    cli()
