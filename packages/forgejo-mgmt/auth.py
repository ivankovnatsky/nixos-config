"""Authentication helpers for forgejo-mgmt."""

import os
import sys
import subprocess

import requests

from utils import read_file


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
        print(
            f"Users already exist ({len(lines)} found), skipping admin user creation",
            file=sys.stderr,
        )
        return

    print(f"Creating admin user: {username}", file=sys.stderr)
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
        print(
            f"ERROR: Failed to create admin user: {result.stderr}",
            file=sys.stderr,
        )
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
                print(
                    "Stored token is invalid, regenerating...",
                    file=sys.stderr,
                )
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
        print(
            f"ERROR: Failed to create API token: {response.text}",
            file=sys.stderr,
        )
        sys.exit(1)

    token = response.json().get("sha1")
    if not token:
        print(
            f"ERROR: No token in response: {response.text}",
            file=sys.stderr,
        )
        sys.exit(1)

    if token_file:
        with open(token_file, "w") as f:
            f.write(token)
        os.chmod(token_file, 0o600)

    print("API token created", file=sys.stderr)
    return token


def create_user_token(
    base_url: str,
    username: str,
    password: str,
    token_name: str = "forgejo-mgmt",
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
            print(
                f"  Token already exists for {username}, skipping",
                file=sys.stderr,
            )
        else:
            print(
                f"  ERROR: Failed to create token for {username} "
                f"(HTTP {response.status_code}): {response.text}",
                file=sys.stderr,
            )
        return ""
    return response.json().get("sha1", "")
