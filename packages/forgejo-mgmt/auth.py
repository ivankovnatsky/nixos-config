"""Authentication helpers for forgejo-mgmt."""

import os
import subprocess
import sys

import click
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
        click.echo(
            f"ERROR: Failed to create admin user: {result.stderr}",
            err=True,
        )
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
                click.echo(
                    "Stored token is invalid, regenerating...",
                    err=True,
                )
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
        click.echo(
            f"ERROR: Failed to create API token: {response.text}",
            err=True,
        )
        sys.exit(1)

    token = response.json().get("sha1")
    if not token:
        click.echo(
            f"ERROR: No token in response: {response.text}",
            err=True,
        )
        sys.exit(1)

    if token_file:
        with open(token_file, "w") as f:
            f.write(token)
        os.chmod(token_file, 0o600)

    click.echo("API token created", err=True)
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
            click.echo(
                f"  Token already exists for {username}, skipping",
                err=True,
            )
        else:
            click.echo(
                f"  ERROR: Failed to create token for {username} "
                f"(HTTP {response.status_code}): {response.text}",
                err=True,
            )
        return ""
    return response.json().get("sha1", "")
