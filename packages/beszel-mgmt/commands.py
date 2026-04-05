"""Command handlers for beszel-mgmt CLI."""

import sys
import json

import click


def cmd_list(output_format, client):
    """List all systems."""
    try:
        systems = client.list_systems()
        if output_format == "json":
            click.echo(json.dumps(systems, indent=2))
        else:
            click.echo("Systems:")
            for system in systems:
                click.echo(
                    f"  {system['id']}: {system['name']} ({system['host']}:{system['port']})"
                )
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


def cmd_get(system_id, client):
    """Get system details."""
    try:
        system = client.get_system(system_id)
        click.echo(json.dumps(system, indent=2))
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


def cmd_create(name, host, port, client):
    """Create a new system."""
    try:
        system = client.create_system(name, host, port)
        click.echo(f"Created system: {system['id']}")
        click.echo(json.dumps(system, indent=2))
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


def cmd_update(system_id, name, host, port, client):
    """Update a system."""
    try:
        system = client.update_system(system_id, name, host, port)
        click.echo(f"Updated system: {system_id}")
        click.echo(json.dumps(system, indent=2))
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


def cmd_delete(system_id, client):
    """Delete a system."""
    try:
        client.delete_system(system_id)
        click.echo(f"Deleted system: {system_id}")
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


def cmd_sync(config_file, dry_run, discord_webhook, client):
    """Sync systems from configuration file."""
    try:
        client.sync_from_file(
            config_file, dry_run=dry_run, discord_webhook=discord_webhook
        )
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)
