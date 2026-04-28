#!/usr/bin/env python3

import subprocess
import sys

import click


def get_network_services():
    """Get list of active network services (excluding disabled ones)."""
    result = subprocess.run(
        ["networksetup", "-listallnetworkservices"],
        capture_output=True,
        text=True,
        check=True,
    )
    # Skip first line (header) and filter out disabled services (starting with *)
    services = [
        line.strip()
        for line in result.stdout.splitlines()[1:]
        if line.strip() and not line.startswith("*")
    ]
    return services


def get_dns_servers(service):
    """Get DNS servers for a specific network service."""
    try:
        result = subprocess.run(
            ["networksetup", "-getdnsservers", service],
            capture_output=True,
            text=True,
            check=True,
        )
        output = result.stdout.strip()
        if "aren't any" in output or not output:
            return None
        return output.splitlines()
    except subprocess.CalledProcessError:
        return "error"


def show_current_dns():
    """Display current DNS configuration for all network services."""
    services = get_network_services()
    click.echo("Current DNS configuration:")
    for service in services:
        click.echo(f"  {service}:")
        dns_servers = get_dns_servers(service)
        if dns_servers is None:
            click.echo("    (using DHCP)")
        elif dns_servers == "error":
            click.echo("    (error retrieving DNS settings)")
        else:
            for server in dns_servers:
                click.echo(f"    {server}")


def set_dns_servers(servers):
    """Set DNS servers for all network services."""
    services = get_network_services()
    click.echo(f"Setting DNS servers to: {' '.join(servers)}")
    for service in services:
        click.echo(f"  - {service}")
        try:
            subprocess.run(
                ["networksetup", "-setdnsservers", service] + list(servers),
                check=True,
                capture_output=True,
            )
        except subprocess.CalledProcessError as e:
            click.echo(f"    Error: {e.stderr.decode().strip()}", err=True)


def clear_dns_servers():
    """Clear DNS servers for all network services (use DHCP)."""
    services = get_network_services()
    click.echo("Clearing DNS servers for all network interfaces...")
    for service in services:
        click.echo(f"  - {service}")
        try:
            subprocess.run(
                ["networksetup", "-setdnsservers", service, "Empty"],
                check=True,
                capture_output=True,
            )
        except subprocess.CalledProcessError as e:
            click.echo(f"    Error: {e.stderr.decode().strip()}", err=True)


def flush_dns_cache_impl():
    """Flush the DNS cache."""
    click.echo("Flushing DNS cache...")
    try:
        subprocess.run(["dscacheutil", "-flushcache"], check=True)
        subprocess.run(["killall", "-HUP", "mDNSResponder"], check=True)
        click.echo("DNS cache flushed successfully")
    except subprocess.CalledProcessError as e:
        click.echo(f"Error flushing DNS cache: {e}", err=True)
        sys.exit(1)


@click.group(invoke_without_command=True)
@click.argument("servers", nargs=-1)
@click.pass_context
def main(ctx, servers):
    """Manage macOS DNS configuration."""
    if ctx.invoked_subcommand is None:
        if servers:
            # If the first argument is "clear" or "flush", manually dispatch
            # This is a workaround for Click consuming subcommands as arguments
            if servers[0].lower() == "clear":
                ctx.invoke(clear)
            elif servers[0].lower() == "flush":
                ctx.invoke(flush)
            else:
                set_dns_servers(servers)
                click.echo()
                show_current_dns()
        else:
            show_current_dns()


@main.command()
def clear():
    """Clear DNS servers for all network interfaces (use DHCP)."""
    clear_dns_servers()
    click.echo()
    show_current_dns()


@main.command()
def flush():
    """Flush DNS cache."""
    flush_dns_cache_impl()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        click.echo("\nInterrupted", err=True)
        sys.exit(130)
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)
