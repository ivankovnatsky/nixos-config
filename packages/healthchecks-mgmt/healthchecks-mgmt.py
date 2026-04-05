#!/usr/bin/env python3
"""
Declarative healthchecks.io check management tool.
Syncs check configuration via the healthchecks.io Management API v3.
"""

import os
import sys
import json
import requests
import click

USER_AGENT = "healthchecks-mgmt/1.0.0"

SYNC_FIELDS = ["timeout", "grace", "tags", "channels", "slug"]


class HealthChecksClient:
    def __init__(self, api_key: str, api_url: str = "https://healthchecks.io"):
        self.api_key = api_key
        self.api_url = api_url.rstrip("/")
        self.headers = {
            "X-Api-Key": api_key,
            "User-Agent": USER_AGENT,
            "Content-Type": "application/json",
        }

    def _api_call(self, method: str, endpoint: str, data=None):
        url = f"{self.api_url}{endpoint}"
        try:
            response = requests.request(
                method, url, json=data, headers=self.headers, timeout=30
            )
            if response.status_code == 204:
                return None
            if response.status_code not in (200, 201):
                try:
                    error_data = response.json()
                    click.echo(f"API error: {error_data}", err=True)
                except ValueError:
                    click.echo(f"API error: {response.text}", err=True)
                raise Exception(
                    f"API request failed with status {response.status_code}"
                )
            return response.json()
        except requests.exceptions.RequestException as e:
            raise Exception(f"Network error: {e}")

    def list_checks(self):
        data = self._api_call("GET", "/api/v3/checks/")
        return data.get("checks", [])

    def create_check(self, check_data: dict):
        return self._api_call("POST", "/api/v3/checks/", data=check_data)

    def update_check(self, uuid: str, check_data: dict):
        return self._api_call("POST", f"/api/v3/checks/{uuid}", data=check_data)

    def delete_check(self, uuid: str):
        return self._api_call("DELETE", f"/api/v3/checks/{uuid}")

    def list_channels(self):
        data = self._api_call("GET", "/api/v3/channels/")
        return data.get("channels", [])


def _check_needs_update(existing: dict, desired: dict) -> list:
    changes = []
    for field in SYNC_FIELDS:
        if field not in desired:
            continue
        desired_val = desired[field]
        existing_val = existing.get(field)
        if field == "channels" and desired_val == "*":
            continue
        if str(desired_val) != str(existing_val):
            changes.append((field, existing_val, desired_val))
    return changes


def sync_from_file(client: HealthChecksClient, config_path: str, dry_run: bool):
    with open(config_path, "r") as f:
        config = json.load(f)

    desired_checks = config.get("checks", [])
    if not desired_checks:
        click.echo("No checks defined in config file.")
        return

    existing_checks = client.list_checks()
    existing_by_name = {c["name"]: c for c in existing_checks}
    desired_names = {c["name"] for c in desired_checks}

    created = 0
    updated = 0
    deleted = 0
    unchanged = 0

    for desired in desired_checks:
        name = desired["name"]
        existing = existing_by_name.get(name)

        if existing is None:
            if dry_run:
                click.echo(f"  Would create: {name}")
            else:
                result = client.create_check(desired)
                ping_url = result.get("ping_url", "")
                click.echo(f"  Created: {name} ({ping_url})")
            created += 1
        else:
            changes = _check_needs_update(existing, desired)
            if changes:
                if dry_run:
                    click.echo(f"  Would update: {name}")
                    for field, old, new in changes:
                        click.echo(f"    {field}: {old} -> {new}")
                else:
                    client.update_check(existing["uuid"], desired)
                    click.echo(f"  Updated: {name}")
                    for field, old, new in changes:
                        click.echo(f"    {field}: {old} -> {new}")
                updated += 1
            else:
                ping_url = existing.get("ping_url", "")
                click.echo(f"  Unchanged: {name} ({ping_url})")
                unchanged += 1

    for name, existing in existing_by_name.items():
        if name not in desired_names:
            uuid = existing["uuid"]
            if dry_run:
                click.echo(f"  Would delete: {name}")
            else:
                client.delete_check(uuid)
                click.echo(f"  Deleted: {name}")
            deleted += 1

    action = "Dry run" if dry_run else "Sync"
    click.echo(
        f"\n{action} complete: "
        f"{created} created, {updated} updated, "
        f"{deleted} deleted, {unchanged} unchanged"
    )


@click.group()
@click.option(
    "--api-key",
    default=lambda: os.environ.get("HEALTHCHECKS_API_KEY"),
    help="API key (or set HEALTHCHECKS_API_KEY env var)",
)
@click.option(
    "--api-url",
    default=lambda: os.environ.get("HEALTHCHECKS_API_URL", "https://healthchecks.io"),
    help="API base URL (default: https://healthchecks.io)",
)
@click.pass_context
def cli(ctx, api_key, api_url):
    """Declarative healthchecks.io management tool."""
    if not api_key:
        click.echo(
            "Error: --api-key or HEALTHCHECKS_API_KEY env var required",
            err=True,
        )
        sys.exit(1)
    ctx.ensure_object(dict)
    ctx.obj["client"] = HealthChecksClient(api_key, api_url)


@cli.command("list")
@click.pass_context
def cmd_list(ctx):
    """List all checks."""
    client = ctx.obj["client"]
    checks = client.list_checks()
    if not checks:
        click.echo("No checks found.")
        return
    for check in checks:
        status = check.get("status", "unknown")
        name = check.get("name", "unnamed")
        timeout = check.get("timeout", "?")
        grace = check.get("grace", "?")
        tags = check.get("tags", "")
        click.echo(
            f"  [{status:>8}] {name} (timeout={timeout}s, grace={grace}s, tags={tags})"
        )


@cli.command("sync")
@click.option(
    "--config-file", required=True, help="JSON config file with check definitions"
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Show what would be changed without making changes",
)
@click.pass_context
def cmd_sync(ctx, config_file, dry_run):
    """Sync checks from config file."""
    client = ctx.obj["client"]
    if not os.path.exists(config_file):
        click.echo(f"Config file not found: {config_file}", err=True)
        sys.exit(1)

    click.echo(f"Syncing checks from {config_file}...")
    sync_from_file(client, config_file, dry_run)


def main():
    cli()


if __name__ == "__main__":
    main()
