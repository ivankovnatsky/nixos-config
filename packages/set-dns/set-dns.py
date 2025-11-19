#!/usr/bin/env python3

import subprocess
import sys


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
    print("Current DNS configuration:")
    for service in services:
        print(f"  {service}:")
        dns_servers = get_dns_servers(service)
        if dns_servers is None:
            print("    (using DHCP)")
        elif dns_servers == "error":
            print("    (error retrieving DNS settings)")
        else:
            for server in dns_servers:
                print(f"    {server}")


def set_dns_servers(servers):
    """Set DNS servers for all network services."""
    services = get_network_services()
    print(f"Setting DNS servers to: {' '.join(servers)}")
    for service in services:
        print(f"  - {service}")
        try:
            subprocess.run(
                ["networksetup", "-setdnsservers", service] + servers,
                check=True,
                capture_output=True,
            )
        except subprocess.CalledProcessError as e:
            print(f"    Error: {e.stderr.decode().strip()}", file=sys.stderr)


def clear_dns_servers():
    """Clear DNS servers for all network services (use DHCP)."""
    services = get_network_services()
    print("Clearing DNS servers for all network interfaces...")
    for service in services:
        print(f"  - {service}")
        try:
            subprocess.run(
                ["networksetup", "-setdnsservers", service, "Empty"],
                check=True,
                capture_output=True,
            )
        except subprocess.CalledProcessError as e:
            print(f"    Error: {e.stderr.decode().strip()}", file=sys.stderr)


def show_help():
    """Display help message."""
    print("Usage: set-dns [dns1 dns2 ...] | clear")
    print()
    print("Examples:")
    print("  set-dns                        # Show current DNS configuration")
    print("  set-dns 1.1.1.1 1.0.0.1        # Set DNS for all interfaces")
    print("  set-dns 8.8.8.8 8.8.4.4        # Set DNS for all interfaces")
    print("  set-dns clear                  # Clear DNS (use DHCP)")


def main():
    # Show help
    if len(sys.argv) == 2 and sys.argv[1] == "--help":
        show_help()
        return

    # Show current configuration if no arguments
    if len(sys.argv) == 1:
        show_current_dns()
        return

    # Handle clear case
    if len(sys.argv) == 2 and sys.argv[1].lower() == "clear":
        clear_dns_servers()
        print()
        show_current_dns()
        return

    # Set DNS servers
    dns_servers = sys.argv[1:]
    set_dns_servers(dns_servers)
    print()
    show_current_dns()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrupted", file=sys.stderr)
        sys.exit(130)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
