"""Utility functions for forgejo-mgmt."""

import sys
import time

import click
import requests


def wait_for_api(base_url: str, max_retries: int = 30, delay: int = 2):
    click.echo(f"Waiting for Forgejo API at {base_url}...", err=True)
    for i in range(1, max_retries + 1):
        try:
            response = requests.get(f"{base_url}/api/v1/settings/api", timeout=5)
            if response.status_code == 200:
                click.echo(
                    f"Forgejo API is ready (attempt {i}/{max_retries})",
                    err=True,
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
