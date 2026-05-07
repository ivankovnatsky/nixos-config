#!/usr/bin/env python3

import subprocess
import sys

import click


def _is_darwin():
    return sys.platform == "darwin"


# ---------- macOS (networksetup) ----------


def _get_network_services_darwin():
    """Get list of active network services (excluding disabled ones)."""
    result = subprocess.run(
        ["networksetup", "-listallnetworkservices"],
        capture_output=True,
        text=True,
        check=True,
    )
    return [
        line.strip()
        for line in result.stdout.splitlines()[1:]
        if line.strip() and not line.startswith("*")
    ]


def _get_dns_servers_darwin(service):
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


def _show_current_dns_darwin():
    services = _get_network_services_darwin()
    click.echo("Current DNS configuration:")
    for service in services:
        click.echo(f"  {service}:")
        dns_servers = _get_dns_servers_darwin(service)
        if dns_servers is None:
            click.echo("    (using DHCP)")
        elif dns_servers == "error":
            click.echo("    (error retrieving DNS settings)")
        else:
            for server in dns_servers:
                click.echo(f"    {server}")


def _set_dns_servers_darwin(servers):
    services = _get_network_services_darwin()
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


def _clear_dns_servers_darwin():
    services = _get_network_services_darwin()
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


def _flush_dns_cache_darwin():
    click.echo("Flushing DNS cache...")
    try:
        subprocess.run(["dscacheutil", "-flushcache"], check=True)
        subprocess.run(["killall", "-HUP", "mDNSResponder"], check=True)
        click.echo("DNS cache flushed successfully")
    except subprocess.CalledProcessError as e:
        click.echo(f"Error flushing DNS cache: {e}", err=True)
        sys.exit(1)


# ---------- Linux (systemd-resolved) ----------


def _resolvectl_dns_linux():
    """Parse `resolvectl dns` into [(scope, [servers])].

    Output (with possible continuation lines prefixed by whitespace):
        Global: 1.1.1.1 1.0.0.1 45.90.28.0#nextdns
                2a07:a8c0::#nextdns
        Link 2 (eno1): 192.168.50.1
        Link 3 (wlp9s0):
    """
    result = subprocess.run(
        ["resolvectl", "dns"],
        capture_output=True,
        text=True,
        check=True,
    )
    scopes = []
    current = None
    for line in result.stdout.splitlines():
        if not line.strip():
            continue
        if line[0].isspace():
            # Continuation of previous scope's server list.
            if current is not None:
                current[1].extend(line.split())
            continue
        if ":" not in line:
            continue
        label, _, rest = line.partition(":")
        # Collapse "Link N (iface)" → "iface" for darwin-like display.
        if label.startswith("Link "):
            paren = label.find("(")
            if paren != -1 and label.endswith(")"):
                label = label[paren + 1 : -1]
        current = (label, rest.split())
        scopes.append(current)
    return scopes


def _show_current_dns_linux():
    try:
        scopes = _resolvectl_dns_linux()
    except FileNotFoundError:
        click.echo("resolvectl not found; is systemd-resolved installed?", err=True)
        sys.exit(1)
    click.echo("Current DNS configuration:")
    for scope, servers in scopes:
        click.echo(f"  {scope}:")
        if not servers:
            click.echo("    (none)")
        else:
            for server in servers:
                click.echo(f"    {server}")


def _flush_dns_cache_linux():
    click.echo("Flushing DNS cache...")
    try:
        subprocess.run(["resolvectl", "flush-caches"], check=True)
        click.echo("DNS cache flushed successfully")
    except FileNotFoundError:
        click.echo("resolvectl not found; is systemd-resolved installed?", err=True)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        click.echo(f"Error flushing DNS cache: {e}", err=True)
        sys.exit(1)


# ---------- Dispatch ----------


def show_current_dns():
    if _is_darwin():
        _show_current_dns_darwin()
    else:
        _show_current_dns_linux()


def set_dns_servers(servers):
    if _is_darwin():
        _set_dns_servers_darwin(servers)
    else:
        click.echo(
            "Setting DNS is not supported on Linux from this tool — "
            "configure via NixOS (networking.nameservers / services.resolved).",
            err=True,
        )
        sys.exit(2)


def clear_dns_servers():
    if _is_darwin():
        _clear_dns_servers_darwin()
    else:
        click.echo(
            "Clearing DNS is not supported on Linux from this tool — "
            "configure via NixOS (networking.nameservers / services.resolved).",
            err=True,
        )
        sys.exit(2)


def flush_dns_cache_impl():
    if _is_darwin():
        _flush_dns_cache_darwin()
    else:
        _flush_dns_cache_linux()


@click.group(invoke_without_command=True)
@click.argument("servers", nargs=-1)
@click.pass_context
def main(ctx, servers):
    """Manage DNS configuration (macOS + Linux)."""
    if ctx.invoked_subcommand is None:
        if servers:
            # If the first argument is "clear" or "flush", manually dispatch.
            # This is a workaround for Click consuming subcommands as positional
            # arguments when invoke_without_command + nargs=-1 are combined.
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
        main(prog_name="dns")
    except KeyboardInterrupt:
        click.echo("\nInterrupted", err=True)
        sys.exit(130)
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)
