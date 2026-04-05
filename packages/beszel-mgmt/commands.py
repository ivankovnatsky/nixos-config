"""Command handlers for beszel-mgmt CLI."""

import sys
import json


def cmd_list(args, client):
    """List all systems."""
    try:
        systems = client.list_systems()
        if args.output_format == "json":
            print(json.dumps(systems, indent=2))
        else:
            print("Systems:")
            for system in systems:
                print(
                    f"  {system['id']}: {system['name']} ({system['host']}:{system['port']})"
                )
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_get(args, client):
    """Get system details."""
    try:
        system = client.get_system(args.system_id)
        print(json.dumps(system, indent=2))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_create(args, client):
    """Create a new system."""
    try:
        system = client.create_system(args.name, args.host, args.port)
        print(f"Created system: {system['id']}")
        print(json.dumps(system, indent=2))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_update(args, client):
    """Update a system."""
    try:
        system = client.update_system(args.system_id, args.name, args.host, args.port)
        print(f"Updated system: {args.system_id}")
        print(json.dumps(system, indent=2))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_delete(args, client):
    """Delete a system."""
    try:
        client.delete_system(args.system_id)
        print(f"Deleted system: {args.system_id}")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_sync(args, client):
    """Sync systems from configuration file."""
    try:
        client.sync_from_file(
            args.config_file, dry_run=args.dry_run, discord_webhook=args.discord_webhook
        )
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
