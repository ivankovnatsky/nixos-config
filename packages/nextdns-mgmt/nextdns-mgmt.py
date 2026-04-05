#!/usr/bin/env python3
"""
NextDNS profile management tool.
Supports sync (declarative) and export operations.
"""

import sys
import json
import requests
import click

API_BASE = "https://api.nextdns.io"
USER_AGENT = "nextdns-mgmt/1.0.0"


class NextDNSClient:
    def __init__(self, api_key: str, timeout: int = 120):
        self.api_key = api_key
        self.timeout = timeout
        self.headers = {"X-Api-Key": api_key, "User-Agent": USER_AGENT}

    def _api_call(self, method: str, endpoint: str, data=None):
        """Make API request with error handling."""
        url = f"{API_BASE}{endpoint}"
        try:
            response = requests.request(
                method, url, json=data, headers=self.headers, timeout=self.timeout
            )

            if response.status_code == 429:
                raise Exception("API rate limit exceeded. Please wait before retrying.")

            if response.status_code == 204:
                return None

            if response.status_code not in (200, 201):
                try:
                    error_data = response.json()
                    click.echo(f"DEBUG: Error response: {error_data}", err=True)
                    errors = error_data.get("errors", [{"detail": "Unknown error"}])
                    detail = (
                        errors[0].get("detail", "Unknown error")
                        if errors
                        else "Unknown error"
                    )
                    raise Exception(
                        f"API error: {detail} (Status: {response.status_code})"
                    )
                except ValueError:
                    click.echo(f"DEBUG: Response text: {response.text}", err=True)
                    raise Exception(
                        f"API request failed with status {response.status_code}"
                    )

            return response.json()
        except requests.exceptions.RequestException as e:
            raise Exception(f"Network error: {e}")

    def get_profiles(self):
        """Get all profiles."""
        data = self._api_call("GET", "/profiles")
        return data.get("data", [])

    def get_profile(self, profile_id: str):
        """Get single profile details."""
        return self._api_call("GET", f"/profiles/{profile_id}")

    def export_profile_raw(self, profile_id: str):
        """Export complete profile configuration (raw API response)."""
        profile_response = self.get_profile(profile_id)
        return json.dumps(profile_response, indent=2)

    def export_profile_filtered(self, profile_id: str):
        """Export profile with sensitive/machine-specific data removed."""
        profile_response = self.get_profile(profile_id)

        if "data" not in profile_response:
            raise ValueError("Invalid profile response format")

        data = profile_response["data"].copy()

        # Remove machine-specific identity/setup fields
        data.pop("id", None)
        data.pop("fingerprint", None)
        data.pop("name", None)
        data.pop("setup", None)

        # Remove rewrites (contain server-assigned IDs not suitable for export)
        data.pop("rewrites", None)

        # Clean privacy blocklists metadata (keep only id)
        if "privacy" in data and "blocklists" in data["privacy"]:
            for blocklist in data["privacy"]["blocklists"]:
                blocklist.pop("name", None)
                blocklist.pop("website", None)
                blocklist.pop("description", None)
                blocklist.pop("entries", None)
                blocklist.pop("updatedOn", None)

        # Sort all arrays alphabetically for consistent output
        if "denylist" in data:
            data["denylist"] = sorted(data["denylist"], key=lambda x: x.get("id", ""))

        if "allowlist" in data:
            data["allowlist"] = sorted(data["allowlist"], key=lambda x: x.get("id", ""))

        if "security" in data and "tlds" in data["security"]:
            data["security"]["tlds"] = sorted(
                data["security"]["tlds"], key=lambda x: x.get("id", "")
            )

        if "privacy" in data:
            if "blocklists" in data["privacy"]:
                data["privacy"]["blocklists"] = sorted(
                    data["privacy"]["blocklists"], key=lambda x: x.get("id", "")
                )
            if "natives" in data["privacy"]:
                data["privacy"]["natives"] = sorted(
                    data["privacy"]["natives"], key=lambda x: x.get("id", "")
                )

        if "parentalControl" in data:
            if "categories" in data["parentalControl"]:
                data["parentalControl"]["categories"] = sorted(
                    data["parentalControl"]["categories"], key=lambda x: x.get("id", "")
                )
            if "services" in data["parentalControl"]:
                data["parentalControl"]["services"] = sorted(
                    data["parentalControl"]["services"], key=lambda x: x.get("id", "")
                )

        return json.dumps({"data": data}, indent=2)


@click.group()
def cli():
    """NextDNS profile management tool."""
    pass


@cli.command()
@click.option("--api-key", required=True, help="NextDNS API key")
@click.option("--profile-id", required=True, help="Profile ID to sync")
@click.option(
    "--profile-file",
    required=True,
    help="NextDNS profile JSON file (profile.json)",
)
@click.option(
    "--dry-run",
    is_flag=True,
    default=False,
    help="Show what would be changed without making changes",
)
def sync(api_key, profile_id, profile_file, dry_run):
    """Send raw unfiltered PATCH request (for testing read-only fields)."""
    client = NextDNSClient(api_key)
    try:
        # Load profile JSON
        with open(profile_file, "r") as f:
            profile_data = json.load(f)

        # Support raw API response {"data": {...}} format only
        if "data" in profile_data:
            profile = profile_data["data"]
        else:
            raise ValueError('Invalid profile JSON format - expected {"data": {...}}')

        click.echo(f"Syncing profile {profile_id} (RAW PATCH - NO FILTERING)...")
        click.echo(f"DEBUG: Sending all fields: {list(profile.keys())}", err=True)
    except Exception as e:
        click.echo(f"Error loading profile file: {e}", err=True)
        sys.exit(1)

    if dry_run:
        click.echo("Dry-run complete - no changes made.")
        sys.exit(0)

    try:
        # Send raw PATCH request with UNFILTERED profile data
        # This will help identify which fields cause errors
        click.echo(f"DEBUG: Sending PATCH to /profiles/{profile_id}", err=True)
        response = client._api_call("PATCH", f"/profiles/{profile_id}", data=profile)
        click.echo("Profile synced successfully!")
        click.echo(f"Response: {json.dumps(response, indent=2)}")
    except Exception as e:
        click.echo(f"Error syncing profile {profile_id}: {e}", err=True)
        sys.exit(1)


@cli.command()
@click.option("--api-key", required=True, help="NextDNS API key")
@click.option("--profile-id", required=True, help="Profile ID to update")
@click.option("--profile-file", required=True, help="NextDNS profile JSON file")
@click.option(
    "--dry-run",
    is_flag=True,
    default=False,
    help="Show what would be updated without making changes",
)
def update(api_key, profile_id, profile_file, dry_run):
    """Update profile using nested endpoints (section by section)."""
    client = NextDNSClient(api_key)
    try:
        # Load profile JSON
        with open(profile_file, "r") as f:
            profile_data = json.load(f)

        # Support both raw API response {"data": {...}} and wrapped {"profile": {"data": {...}}}
        if "data" in profile_data:
            # Raw API response format or filtered export
            profile = profile_data["data"]
        elif "profile" in profile_data and "data" in profile_data["profile"]:
            # Wrapped format (legacy)
            profile = profile_data["profile"]["data"]
        else:
            raise ValueError("Invalid profile JSON format")

        click.echo(f"Updating profile {profile_id} using nested endpoints...")

        # Update sections using nested endpoints (in order)
        sections = ["security", "privacy", "parentalControl"]

        for section in sections:
            if section in profile:
                if dry_run:
                    click.echo(f"  Would update {section}")
                else:
                    try:
                        section_data = profile[section].copy()

                        # Clean privacy blocklists metadata
                        if section == "privacy" and "blocklists" in section_data:
                            for blocklist in section_data["blocklists"]:
                                blocklist.pop("name", None)
                                blocklist.pop("website", None)
                                blocklist.pop("description", None)
                                blocklist.pop("entries", None)
                                blocklist.pop("updatedOn", None)

                        # ParentalControl: remove arrays, handle separately below
                        parental_services = None
                        parental_categories = None
                        if section == "parentalControl":
                            parental_services = section_data.pop("services", None)
                            parental_categories = section_data.pop("categories", None)

                        client._api_call(
                            "PATCH",
                            f"/profiles/{profile_id}/{section}",
                            data=section_data,
                        )
                        click.echo(f"  ✓ Updated {section}")

                        # Update parentalControl arrays using dedicated endpoints
                        if section == "parentalControl":
                            if parental_categories is not None:
                                try:
                                    client._api_call(
                                        "PUT",
                                        f"/profiles/{profile_id}/parentalControl/categories",
                                        data=parental_categories,
                                    )
                                    click.echo("  ✓ Updated parentalControl/categories")
                                except Exception as e:
                                    click.echo(
                                        f"  ✗ Failed to update parentalControl/categories: {e}",
                                        err=True,
                                    )
                            if parental_services is not None:
                                try:
                                    client._api_call(
                                        "PUT",
                                        f"/profiles/{profile_id}/parentalControl/services",
                                        data=parental_services,
                                    )
                                    click.echo("  ✓ Updated parentalControl/services")
                                except Exception as e:
                                    click.echo(
                                        f"  ✗ Failed to update parentalControl/services: {e}",
                                        err=True,
                                    )
                    except Exception as e:
                        click.echo(f"  ✗ Failed to update {section}: {e}", err=True)

        # Update denylist
        if "denylist" in profile:
            desired_denylist = {
                entry["id"]
                for entry in profile["denylist"]
                if entry.get("active", True)
            }
            if dry_run:
                click.echo(f"  Would sync denylist ({len(desired_denylist)} domains)")
            else:
                try:
                    current_data = client._api_call(
                        "GET", f"/profiles/{profile_id}/denylist"
                    )
                    current_denylist = {
                        entry["id"] for entry in current_data.get("data", [])
                    }

                    to_add = desired_denylist - current_denylist
                    to_remove = current_denylist - desired_denylist

                    if to_add or to_remove:
                        click.echo("  Denylist changes:", err=True)
                        if to_add:
                            click.echo(f"    Adding: {sorted(to_add)}", err=True)
                        if to_remove:
                            click.echo(f"    Removing: {sorted(to_remove)}", err=True)

                    for domain in to_add:
                        client._api_call(
                            "POST",
                            f"/profiles/{profile_id}/denylist",
                            data={"id": domain, "active": True},
                        )

                    for domain in to_remove:
                        client._api_call(
                            "DELETE", f"/profiles/{profile_id}/denylist/{domain}"
                        )

                    click.echo(
                        f"  ✓ Updated denylist (+{len(to_add)} -{len(to_remove)})"
                    )
                except Exception as e:
                    click.echo(f"  ✗ Failed to update denylist: {e}", err=True)

        # Update allowlist
        if "allowlist" in profile:
            desired_allowlist = {
                entry["id"]
                for entry in profile["allowlist"]
                if entry.get("active", True)
            }
            if dry_run:
                click.echo(f"  Would sync allowlist ({len(desired_allowlist)} domains)")
            else:
                try:
                    current_data = client._api_call(
                        "GET", f"/profiles/{profile_id}/allowlist"
                    )
                    current_allowlist = {
                        entry["id"] for entry in current_data.get("data", [])
                    }

                    to_add = desired_allowlist - current_allowlist
                    to_remove = current_allowlist - desired_allowlist

                    if to_add or to_remove:
                        click.echo("  Allowlist changes:", err=True)
                        if to_add:
                            click.echo(f"    Adding: {sorted(to_add)}", err=True)
                        if to_remove:
                            click.echo(f"    Removing: {sorted(to_remove)}", err=True)

                    for domain in to_add:
                        client._api_call(
                            "POST",
                            f"/profiles/{profile_id}/allowlist",
                            data={"id": domain, "active": True},
                        )

                    for domain in to_remove:
                        client._api_call(
                            "DELETE", f"/profiles/{profile_id}/allowlist/{domain}"
                        )

                    click.echo(
                        f"  ✓ Updated allowlist (+{len(to_add)} -{len(to_remove)})"
                    )
                except Exception as e:
                    click.echo(f"  ✗ Failed to update allowlist: {e}", err=True)

        # Update rewrites
        if "rewrites" in profile:
            desired_rewrites = [
                {"name": r["name"], "content": r["content"]}
                for r in profile["rewrites"]
            ]

            if dry_run:
                click.echo(f"  Would sync rewrites ({len(desired_rewrites)} entries)")
                for r in desired_rewrites:
                    click.echo(f"    {r['name']} → {r['content']}")
            else:
                try:
                    current_data = client._api_call(
                        "GET", f"/profiles/{profile_id}/rewrites"
                    )
                    current_rewrites = current_data.get("data", [])
                    current_set = {(r["name"], r["content"]) for r in current_rewrites}
                    desired_set = {(r["name"], r["content"]) for r in desired_rewrites}

                    to_add = desired_set - current_set
                    to_remove = current_set - desired_set

                    # Build id lookup for removals
                    id_lookup = {
                        (r["name"], r["content"]): r["id"] for r in current_rewrites
                    }

                    if to_add or to_remove:
                        click.echo("  Rewrite changes:", err=True)
                        if to_add:
                            click.echo(
                                f"    Adding: {sorted(to_add)}",
                                err=True,
                            )
                        if to_remove:
                            click.echo(
                                f"    Removing: {sorted(to_remove)}",
                                err=True,
                            )

                    for name, content in to_add:
                        client._api_call(
                            "POST",
                            f"/profiles/{profile_id}/rewrites",
                            data={"name": name, "content": content},
                        )

                    for name, content in to_remove:
                        rewrite_id = id_lookup.get((name, content))
                        if rewrite_id:
                            client._api_call(
                                "DELETE",
                                f"/profiles/{profile_id}/rewrites/{rewrite_id}",
                            )

                    click.echo(
                        f"  ✓ Updated rewrites (+{len(to_add)} -{len(to_remove)})"
                    )
                except Exception as e:
                    click.echo(f"  ✗ Failed to update rewrites: {e}", err=True)

        # Update settings last
        if "settings" in profile:
            if dry_run:
                click.echo("  Would update settings")
            else:
                try:
                    client._api_call(
                        "PATCH",
                        f"/profiles/{profile_id}/settings",
                        data=profile["settings"],
                    )
                    click.echo("  ✓ Updated settings")
                except Exception as e:
                    click.echo(f"  ✗ Failed to update settings: {e}", err=True)

        if dry_run:
            click.echo("Dry-run complete - no changes made.")
        else:
            click.echo("Profile updated successfully!")

    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


@cli.command(name="export")
@click.option("--api-key", required=True, help="NextDNS API key")
@click.option(
    "--profile-id",
    default=None,
    help="Profile ID to export (required unless using --list-profiles)",
)
@click.option("--output", default=None, help="Output file (default: stdout)")
@click.option(
    "--list-profiles", is_flag=True, default=False, help="List all profiles and exit"
)
def export(api_key, profile_id, output, list_profiles):
    """Export profile configuration (filtered - no sensitive data)."""
    client = NextDNSClient(api_key)
    try:
        if list_profiles:
            profiles = client.get_profiles()
            click.echo("Available profiles:")
            for profile in profiles:
                click.echo(f"  {profile['id']}: {profile['name']}")
            sys.exit(0)

        if not profile_id:
            click.echo(
                "Error: --profile-id is required when not using --list-profiles",
                err=True,
            )
            sys.exit(1)

        out = client.export_profile_filtered(profile_id)

        if output:
            with open(output, "w") as f:
                f.write(out)
            click.echo(f"Exported filtered profile to {output}")
        else:
            click.echo(out)

    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


@cli.command(name="export-raw")
@click.option("--api-key", required=True, help="NextDNS API key")
@click.option(
    "--profile-id",
    default=None,
    help="Profile ID to export (required unless using --list-profiles)",
)
@click.option("--output", default=None, help="Output file (default: stdout)")
@click.option(
    "--list-profiles", is_flag=True, default=False, help="List all profiles and exit"
)
def export_raw(api_key, profile_id, output, list_profiles):
    """Export complete profile configuration (raw API response)."""
    client = NextDNSClient(api_key)
    try:
        if list_profiles:
            profiles = client.get_profiles()
            click.echo("Available profiles:")
            for profile in profiles:
                click.echo(f"  {profile['id']}: {profile['name']}")
            sys.exit(0)

        if not profile_id:
            click.echo(
                "Error: --profile-id is required when not using --list-profiles",
                err=True,
            )
            sys.exit(1)

        out = client.export_profile_raw(profile_id)

        if output:
            with open(output, "w") as f:
                f.write(out)
            click.echo(f"Exported to {output}")
        else:
            click.echo(out)

    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


def main():
    cli()


if __name__ == "__main__":
    main()
