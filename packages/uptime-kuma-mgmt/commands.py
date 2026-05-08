"""CLI command handlers for uptime-kuma-mgmt."""

import sys
import json

import click


def cmd_list(output_format, client):
    """List all monitors."""
    try:
        monitors = client.list_monitors()
        if output_format == "json":
            click.echo(json.dumps(monitors, indent=2))
        else:
            click.echo("Monitors:")
            for monitor in monitors:
                status = "\u2713" if monitor.get("active") else "\u2717"
                target = _get_monitor_target(monitor)
                click.echo(
                    f"  [{status}] {monitor['id']}: {monitor['name']} - {target}"
                )
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


def _get_monitor_target(monitor: dict) -> str:
    """Get the target/connection info for a monitor based on its type."""
    monitor_type = monitor.get("type", "").lower()

    # TCP/Port monitors use hostname:port
    if monitor_type == "port":
        hostname = monitor.get("hostname", "")
        port = monitor.get("port", "")
        if hostname and port:
            return f"tcp://{hostname}:{port}"

    # MQTT monitors use hostname:port
    if monitor_type == "mqtt":
        hostname = monitor.get("hostname", "")
        port = monitor.get("port", "")
        if hostname and port:
            return f"mqtt://{hostname}:{port}"

    # DNS monitors use hostname@dns_server
    if monitor_type == "dns":
        hostname = monitor.get("hostname", "")
        dns_server = monitor.get("dns_resolve_server", "")
        if hostname and dns_server:
            return f"dns://{hostname}@{dns_server}"

    # Postgres monitors use connection string (mask password)
    if monitor_type == "postgres":
        conn_str = monitor.get("databaseConnectionString", "")
        if conn_str:
            # Mask password in connection string
            if "://" in conn_str and "@" in conn_str:
                try:
                    protocol, rest = conn_str.split("://", 1)
                    credentials, host_part = rest.rsplit("@", 1)
                    if ":" in credentials:
                        user, _ = credentials.split(":", 1)
                        return f"{protocol}://{user}:***@{host_part}"
                except Exception:
                    pass
            return conn_str

    # Tailscale Ping monitors use hostname
    if monitor_type == "tailscale-ping":
        hostname = monitor.get("hostname", "")
        if hostname:
            return f"tailscale://{hostname}"

    # HTTP/HTTPS and other types use url
    url = monitor.get("url")
    if url:
        return url

    return "N/A"


def cmd_get(monitor_id, client):
    """Get monitor details."""
    try:
        monitor = client.get_monitor(monitor_id)
        click.echo(json.dumps(monitor, indent=2))
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


def cmd_sync(config_file, dry_run, discord_webhook, notifications_enabled, client):
    """Sync monitors from configuration file."""
    try:
        client.sync_from_file(
            config_file,
            dry_run=dry_run,
            discord_webhook=discord_webhook,
            notifications_enabled=notifications_enabled,
        )
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)
