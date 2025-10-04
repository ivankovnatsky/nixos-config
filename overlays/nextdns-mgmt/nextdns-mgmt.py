#!/usr/bin/env python3
"""
NextDNS profile management tool.
Supports sync (declarative) and export operations.
"""

import sys
import json
import requests
import argparse

API_BASE = "https://api.nextdns.io"
USER_AGENT = "nextdns-mgmt/1.0.0"

class NextDNSClient:
    def __init__(self, api_key: str, timeout: int = 120):
        self.api_key = api_key
        self.timeout = timeout
        self.headers = {
            "X-Api-Key": api_key,
            "User-Agent": USER_AGENT
        }

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
                    print(f"DEBUG: Error response: {error_data}", file=sys.stderr)
                    errors = error_data.get("errors", [{"detail": "Unknown error"}])
                    detail = errors[0].get("detail", "Unknown error") if errors else "Unknown error"
                    raise Exception(f"API error: {detail} (Status: {response.status_code})")
                except ValueError:
                    print(f"DEBUG: Response text: {response.text}", file=sys.stderr)
                    raise Exception(f"API request failed with status {response.status_code}")

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

    def update_profile(self, profile_id: str, profile_data: dict):
        """Update entire profile configuration."""
        # Remove read-only fields
        clean_data = profile_data.copy()

        # Remove top-level read-only fields
        clean_data.pop('id', None)
        clean_data.pop('fingerprint', None)
        clean_data.pop('rewrites', None)

        # Remove denylist/allowlist - these have separate API endpoints
        clean_data.pop('denylist', None)
        clean_data.pop('allowlist', None)

        # Clean setup section
        if 'setup' in clean_data:
            setup = clean_data['setup']
            setup.pop('ipv4', None)
            setup.pop('ipv6', None)
            setup.pop('dnscrypt', None)
            if 'linkedIp' in setup:
                setup['linkedIp'].pop('servers', None)
                setup['linkedIp'].pop('ip', None)
                setup['linkedIp'].pop('updateToken', None)

        # Clean privacy blocklists metadata
        if 'privacy' in clean_data and 'blocklists' in clean_data['privacy']:
            for blocklist in clean_data['privacy']['blocklists']:
                blocklist.pop('name', None)
                blocklist.pop('website', None)
                blocklist.pop('description', None)
                blocklist.pop('entries', None)
                blocklist.pop('updatedOn', None)

        print(f"DEBUG: Sending PATCH to /profiles/{profile_id}", file=sys.stderr)
        print(f"DEBUG: Cleaned payload keys: {list(clean_data.keys())}", file=sys.stderr)
        return self._api_call("PATCH", f"/profiles/{profile_id}", data=clean_data)

    def export_profile(self, profile_id: str):
        """Export complete profile configuration (raw API response)."""
        profile_response = self.get_profile(profile_id)
        return json.dumps(profile_response, indent=2)

def cmd_sync(args, client):
    """Sync command handler."""
    try:
        # Load profile JSON
        with open(args.profile_file, 'r') as f:
            profile_data = json.load(f)

        # Support both raw API response {"data": {...}} and wrapped {"profile": {"data": {...}}}
        if 'data' in profile_data and 'id' in profile_data['data']:
            # Raw API response format
            profile = profile_data['data']
        elif 'profile' in profile_data and 'data' in profile_data['profile']:
            # Wrapped format (legacy)
            profile = profile_data['profile']['data']
        else:
            raise ValueError("Invalid profile JSON format")

        # Validate profile ID matches
        if profile['id'] != args.profile_id:
            print(f"Error: Profile ID mismatch - file contains '{profile['id']}' but --profile-id specified '{args.profile_id}'", file=sys.stderr)
            sys.exit(1)

        print(f"Syncing profile {args.profile_id}...")
    except Exception as e:
        print(f"Error loading profile file: {e}", file=sys.stderr)
        sys.exit(1)

    if args.dry_run:
        print("Dry-run complete - no changes made.")
        sys.exit(0)

    try:
        # Update entire profile configuration
        client.update_profile(args.profile_id, profile)
        print("Profile synced successfully!")
    except Exception as e:
        print(f"Error syncing profile {args.profile_id}: {e}", file=sys.stderr)
        sys.exit(1)

def cmd_update(args, client):
    """Update profile using nested endpoints (section by section)."""
    try:
        # Load profile JSON
        with open(args.profile_file, 'r') as f:
            profile_data = json.load(f)

        # Support both raw API response {"data": {...}} and wrapped {"profile": {"data": {...}}}
        if 'data' in profile_data and 'id' in profile_data['data']:
            # Raw API response format
            profile = profile_data['data']
        elif 'profile' in profile_data and 'data' in profile_data['profile']:
            # Wrapped format (legacy)
            profile = profile_data['profile']['data']
        else:
            raise ValueError("Invalid profile JSON format")

        # Validate profile ID matches
        if profile['id'] != args.profile_id:
            print(f"Error: Profile ID mismatch - file contains '{profile['id']}' but --profile-id specified '{args.profile_id}'", file=sys.stderr)
            sys.exit(1)

        print(f"Updating profile {args.profile_id} using nested endpoints...")

        # Update sections using nested endpoints (in order)
        sections = ['security', 'privacy', 'parentalControl']

        for section in sections:
            if section in profile:
                if args.dry_run:
                    print(f"  Would update {section}")
                else:
                    try:
                        section_data = profile[section].copy()

                        # Clean privacy blocklists metadata
                        if section == 'privacy' and 'blocklists' in section_data:
                            for blocklist in section_data['blocklists']:
                                blocklist.pop('name', None)
                                blocklist.pop('website', None)
                                blocklist.pop('description', None)
                                blocklist.pop('entries', None)
                                blocklist.pop('updatedOn', None)

                        # ParentalControl: remove arrays, handle separately below
                        parental_services = None
                        parental_categories = None
                        if section == 'parentalControl':
                            parental_services = section_data.pop('services', None)
                            parental_categories = section_data.pop('categories', None)

                        client._api_call("PATCH", f"/profiles/{args.profile_id}/{section}", data=section_data)
                        print(f"  ✓ Updated {section}")

                        # Update parentalControl arrays using dedicated endpoints
                        if section == 'parentalControl':
                            if parental_categories is not None:
                                try:
                                    client._api_call("PUT", f"/profiles/{args.profile_id}/parentalControl/categories", data=parental_categories)
                                    print(f"  ✓ Updated parentalControl/categories")
                                except Exception as e:
                                    print(f"  ✗ Failed to update parentalControl/categories: {e}", file=sys.stderr)
                            if parental_services is not None:
                                try:
                                    client._api_call("PUT", f"/profiles/{args.profile_id}/parentalControl/services", data=parental_services)
                                    print(f"  ✓ Updated parentalControl/services")
                                except Exception as e:
                                    print(f"  ✗ Failed to update parentalControl/services: {e}", file=sys.stderr)
                    except Exception as e:
                        print(f"  ✗ Failed to update {section}: {e}", file=sys.stderr)

        # Update denylist
        if 'denylist' in profile:
            desired_denylist = {entry['id'] for entry in profile['denylist'] if entry.get('active', True)}
            if args.dry_run:
                print(f"  Would sync denylist ({len(desired_denylist)} domains)")
            else:
                try:
                    current_data = client._api_call("GET", f"/profiles/{args.profile_id}/denylist")
                    current_denylist = {entry['id'] for entry in current_data.get('data', [])}

                    to_add = desired_denylist - current_denylist
                    to_remove = current_denylist - desired_denylist

                    if to_add or to_remove:
                        print(f"  Denylist changes:", file=sys.stderr)
                        if to_add:
                            print(f"    Adding: {sorted(to_add)}", file=sys.stderr)
                        if to_remove:
                            print(f"    Removing: {sorted(to_remove)}", file=sys.stderr)

                    for domain in to_add:
                        client._api_call("POST", f"/profiles/{args.profile_id}/denylist", data={"id": domain, "active": True})

                    for domain in to_remove:
                        client._api_call("DELETE", f"/profiles/{args.profile_id}/denylist/{domain}")

                    print(f"  ✓ Updated denylist (+{len(to_add)} -{len(to_remove)})")
                except Exception as e:
                    print(f"  ✗ Failed to update denylist: {e}", file=sys.stderr)

        # Update allowlist
        if 'allowlist' in profile:
            desired_allowlist = {entry['id'] for entry in profile['allowlist'] if entry.get('active', True)}
            if args.dry_run:
                print(f"  Would sync allowlist ({len(desired_allowlist)} domains)")
            else:
                try:
                    current_data = client._api_call("GET", f"/profiles/{args.profile_id}/allowlist")
                    current_allowlist = {entry['id'] for entry in current_data.get('data', [])}

                    to_add = desired_allowlist - current_allowlist
                    to_remove = current_allowlist - desired_allowlist

                    if to_add or to_remove:
                        print(f"  Allowlist changes:", file=sys.stderr)
                        if to_add:
                            print(f"    Adding: {sorted(to_add)}", file=sys.stderr)
                        if to_remove:
                            print(f"    Removing: {sorted(to_remove)}", file=sys.stderr)

                    for domain in to_add:
                        client._api_call("POST", f"/profiles/{args.profile_id}/allowlist", data={"id": domain, "active": True})

                    for domain in to_remove:
                        client._api_call("DELETE", f"/profiles/{args.profile_id}/allowlist/{domain}")

                    print(f"  ✓ Updated allowlist (+{len(to_add)} -{len(to_remove)})")
                except Exception as e:
                    print(f"  ✗ Failed to update allowlist: {e}", file=sys.stderr)

        # Update settings last
        if 'settings' in profile:
            if args.dry_run:
                print(f"  Would update settings")
            else:
                try:
                    client._api_call("PATCH", f"/profiles/{args.profile_id}/settings", data=profile['settings'])
                    print(f"  ✓ Updated settings")
                except Exception as e:
                    print(f"  ✗ Failed to update settings: {e}", file=sys.stderr)

        if args.dry_run:
            print("Dry-run complete - no changes made.")
        else:
            print("Profile updated successfully!")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

def cmd_export(args, client):
    """Export command handler."""
    try:
        if args.list_profiles:
            profiles = client.get_profiles()
            print("Available profiles:")
            for profile in profiles:
                print(f"  {profile['id']}: {profile['name']}")
            sys.exit(0)

        if not args.profile_id:
            print("Error: --profile-id is required when not using --list-profiles", file=sys.stderr)
            sys.exit(1)

        output = client.export_profile(args.profile_id)

        if args.output:
            with open(args.output, 'w') as f:
                f.write(output)
            print(f"Exported to {args.output}")
        else:
            print(output)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(
        description="NextDNS profile management tool"
    )

    subparsers = parser.add_subparsers(dest="command", required=True, help="Command to execute")

    # Sync command
    sync_parser = subparsers.add_parser("sync", help="Sync profile denylist declaratively")
    sync_parser.add_argument(
        "--api-key",
        required=True,
        help="NextDNS API key"
    )
    sync_parser.add_argument(
        "--profile-id",
        required=True,
        help="Profile ID to sync"
    )
    sync_parser.add_argument(
        "--profile-file",
        required=True,
        help="NextDNS profile JSON file (profile.json)"
    )
    sync_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without making changes"
    )

    # Update command
    update_parser = subparsers.add_parser("update", help="Update profile using nested endpoints (section by section)")
    update_parser.add_argument(
        "--api-key",
        required=True,
        help="NextDNS API key"
    )
    update_parser.add_argument(
        "--profile-id",
        required=True,
        help="Profile ID to update"
    )
    update_parser.add_argument(
        "--profile-file",
        required=True,
        help="NextDNS profile JSON file"
    )
    update_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be updated without making changes"
    )

    # Export command
    export_parser = subparsers.add_parser("export", help="Export profile configuration")
    export_parser.add_argument(
        "--api-key",
        required=True,
        help="NextDNS API key"
    )
    export_parser.add_argument(
        "--profile-id",
        help="Profile ID to export (required unless using --list-profiles)"
    )
    export_parser.add_argument(
        "--output",
        help="Output file (default: stdout)"
    )
    export_parser.add_argument(
        "--list-profiles",
        action="store_true",
        help="List all profiles and exit"
    )

    args = parser.parse_args()

    client = NextDNSClient(args.api_key)

    if args.command == "sync":
        cmd_sync(args, client)
    elif args.command == "update":
        cmd_update(args, client)
    elif args.command == "export":
        cmd_export(args, client)

if __name__ == "__main__":
    main()
