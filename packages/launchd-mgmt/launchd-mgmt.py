#!/usr/bin/env python3
"""
launchd-mgmt - A general management tool for macOS launchd services.

Provides unified interface for managing launchd agents (user-level) and
daemons (system-level) with filtering, health checking, and bulk operations.
"""

import argparse
import os
import subprocess
import sys
from dataclasses import dataclass
from enum import Enum
from typing import Optional


class ServiceType(Enum):
    AGENT = "agent"
    DAEMON = "daemon"


@dataclass
class Service:
    name: str
    pid: Optional[int]
    exit_code: Optional[int]
    service_type: ServiceType

    @property
    def is_running(self) -> bool:
        return self.pid is not None and self.pid > 0

    @property
    def is_healthy(self) -> bool:
        return self.exit_code == 0


def run_cmd(cmd: list[str], capture: bool = True, check: bool = True) -> subprocess.CompletedProcess:
    """Run a command and return the result."""
    try:
        return subprocess.run(
            cmd,
            capture_output=capture,
            text=True,
            check=check,
        )
    except subprocess.CalledProcessError as e:
        if capture:
            print(f"Error: {e.stderr}", file=sys.stderr)
        raise


def run_sudo_cmd(cmd: list[str], capture: bool = True, check: bool = True) -> subprocess.CompletedProcess:
    """Run a command with sudo."""
    return run_cmd(["sudo"] + cmd, capture=capture, check=check)


def get_uid() -> int:
    """Get current user ID."""
    return os.getuid()


def parse_launchctl_list(output: str, service_type: ServiceType) -> list[Service]:
    """Parse launchctl list output into Service objects."""
    services = []
    for line in output.strip().split("\n")[1:]:  # Skip header
        parts = line.split("\t")
        if len(parts) >= 3:
            pid_str, exit_code_str, name = parts[0], parts[1], parts[2]
            pid = int(pid_str) if pid_str != "-" else None
            exit_code = int(exit_code_str) if exit_code_str != "-" else None
            services.append(Service(name, pid, exit_code, service_type))
    return services


def list_agents(pattern: Optional[str] = None) -> list[Service]:
    """List user agents, optionally filtered by pattern."""
    result = run_cmd(["launchctl", "list"])
    services = parse_launchctl_list(result.stdout, ServiceType.AGENT)
    if pattern:
        services = [s for s in services if pattern in s.name]
    return services


def list_daemons(pattern: Optional[str] = None) -> list[Service]:
    """List system daemons, optionally filtered by pattern."""
    result = run_sudo_cmd(["launchctl", "list"])
    services = parse_launchctl_list(result.stdout, ServiceType.DAEMON)
    if pattern:
        services = [s for s in services if pattern in s.name]
    return services


def format_service(svc: Service, verbose: bool = False) -> str:
    """Format a service for display."""
    status = "●" if svc.is_running else "○"
    health = "✓" if svc.is_healthy else "✗"
    pid_str = str(svc.pid) if svc.pid else "-"
    exit_str = str(svc.exit_code) if svc.exit_code is not None else "-"

    if verbose:
        return f"{status} {health}  {svc.name:<50} PID: {pid_str:<8} Exit: {exit_str}"
    return f"{status} {health}  {svc.name}"


def cmd_list(args: argparse.Namespace) -> int:
    """List services."""
    show_agents = args.type in ("all", "agents")
    show_daemons = args.type in ("all", "daemons")

    if show_agents:
        print("=== User Agents ===")
        agents = list_agents(args.filter)
        if args.unhealthy:
            agents = [a for a in agents if not a.is_healthy]
        if agents:
            for svc in sorted(agents, key=lambda s: s.name):
                print(format_service(svc, args.verbose))
        else:
            print("None found" if not args.unhealthy else "All healthy")
        print()

    if show_daemons:
        print("=== System Daemons ===")
        daemons = list_daemons(args.filter)
        if args.unhealthy:
            daemons = [d for d in daemons if not d.is_healthy]
        if daemons:
            for svc in sorted(daemons, key=lambda s: s.name):
                print(format_service(svc, args.verbose))
        else:
            print("None found" if not args.unhealthy else "All healthy")

    return 0


def restart_service(name: str, service_type: ServiceType) -> bool:
    """Restart a single service."""
    uid = get_uid()
    if service_type == ServiceType.AGENT:
        target = f"gui/{uid}/{name}"
        cmd = ["launchctl", "kickstart", "-k", target]
    else:
        target = f"system/{name}"
        cmd = ["sudo", "launchctl", "kickstart", "-k", target]

    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"  Failed to restart {name}: {e.stderr}", file=sys.stderr)
        return False


def cmd_restart(args: argparse.Namespace) -> int:
    """Restart services."""
    if args.name:
        svc_type = ServiceType.DAEMON if args.daemon else ServiceType.AGENT
        print(f"Restarting {svc_type.value}: {args.name}")
        success = restart_service(args.name, svc_type)
        return 0 if success else 1

    # Restart unhealthy services
    restart_agents = args.type in ("all", "agents")
    restart_daemons = args.type in ("all", "daemons")
    failed = 0

    if restart_agents:
        print("Checking user agents...")
        agents = list_agents(args.filter)
        unhealthy = [a for a in agents if not a.is_healthy]
        if unhealthy:
            print("Restarting unhealthy agents:")
            for svc in unhealthy:
                print(f"  → {svc.name}")
                if not restart_service(svc.name, ServiceType.AGENT):
                    failed += 1
        else:
            print("All agents are healthy (exit code 0)")
        print()

    if restart_daemons:
        print("Checking system daemons (requires sudo)...")
        daemons = list_daemons(args.filter)
        unhealthy = [d for d in daemons if not d.is_healthy]
        if unhealthy:
            print("Restarting unhealthy daemons:")
            for svc in unhealthy:
                print(f"  → {svc.name}")
                if not restart_service(svc.name, ServiceType.DAEMON):
                    failed += 1
        else:
            print("All daemons are healthy (exit code 0)")

    return 1 if failed > 0 else 0


def get_plist_path(name: str, service_type: ServiceType) -> Optional[str]:
    """Get the plist path for a service."""
    if service_type == ServiceType.AGENT:
        # Check common agent locations
        paths = [
            os.path.expanduser(f"~/Library/LaunchAgents/{name}.plist"),
            f"/Library/LaunchAgents/{name}.plist",
        ]
    else:
        paths = [
            f"/Library/LaunchDaemons/{name}.plist",
        ]

    for path in paths:
        if os.path.exists(path):
            return path
    return None


def stop_service(name: str, service_type: ServiceType) -> bool:
    """Stop a single service using bootout (works with KeepAlive services)."""
    uid = get_uid()
    if service_type == ServiceType.AGENT:
        target = f"gui/{uid}/{name}"
        cmd = ["launchctl", "bootout", target]
    else:
        target = f"system/{name}"
        cmd = ["sudo", "launchctl", "bootout", target]

    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"  Failed to stop {name}: {e.stderr}", file=sys.stderr)
        return False


def start_service(name: str, service_type: ServiceType) -> bool:
    """Start a single service using bootstrap."""
    uid = get_uid()
    plist_path = get_plist_path(name, service_type)

    if not plist_path:
        print(f"  Could not find plist for {name}", file=sys.stderr)
        return False

    if service_type == ServiceType.AGENT:
        target = f"gui/{uid}"
        cmd = ["launchctl", "bootstrap", target, plist_path]
    else:
        target = "system"
        cmd = ["sudo", "launchctl", "bootstrap", target, plist_path]

    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"  Failed to start {name}: {e.stderr}", file=sys.stderr)
        return False


def cmd_stop(args: argparse.Namespace) -> int:
    """Stop a service."""
    svc_type = ServiceType.DAEMON if args.daemon else ServiceType.AGENT
    print(f"Stopping {svc_type.value}: {args.name}")
    success = stop_service(args.name, svc_type)
    return 0 if success else 1


def cmd_start(args: argparse.Namespace) -> int:
    """Start a service."""
    svc_type = ServiceType.DAEMON if args.daemon else ServiceType.AGENT
    print(f"Starting {svc_type.value}: {args.name}")
    success = start_service(args.name, svc_type)
    return 0 if success else 1


def cmd_status(args: argparse.Namespace) -> int:
    """Show status of unhealthy services."""
    show_agents = args.type in ("all", "agents")
    show_daemons = args.type in ("all", "daemons")

    print("=== Unhealthy Services ===\n")

    if show_agents:
        print("User Agents:")
        agents = list_agents(args.filter)
        unhealthy = [a for a in agents if not a.is_healthy]
        if unhealthy:
            for svc in sorted(unhealthy, key=lambda s: s.name):
                print(f"  {format_service(svc, verbose=True)}")
        else:
            print("  All healthy")
        print()

    if show_daemons:
        print("System Daemons:")
        daemons = list_daemons(args.filter)
        unhealthy = [d for d in daemons if not d.is_healthy]
        if unhealthy:
            for svc in sorted(unhealthy, key=lambda s: s.name):
                print(f"  {format_service(svc, verbose=True)}")
        else:
            print("  All healthy")

    return 0


def cmd_info(args: argparse.Namespace) -> int:
    """Show detailed info about a service."""
    uid = get_uid()
    svc_type = ServiceType.DAEMON if args.daemon else ServiceType.AGENT

    if svc_type == ServiceType.AGENT:
        target = f"gui/{uid}/{args.name}"
        cmd = ["launchctl", "print", target]
    else:
        target = f"system/{args.name}"
        cmd = ["sudo", "launchctl", "print", target]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(result.stdout)
        return 0
    except subprocess.CalledProcessError as e:
        print(f"Error: {e.stderr}", file=sys.stderr)
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Manage macOS launchd services (agents and daemons)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  launchd-mgmt list                          # List all services
  launchd-mgmt list -t agents -f mypattern   # List agents matching pattern
  launchd-mgmt list --unhealthy              # List only unhealthy services
  launchd-mgmt status                        # Show unhealthy services
  launchd-mgmt restart                       # Restart all unhealthy services
  launchd-mgmt restart -n myservice          # Restart specific agent
  launchd-mgmt restart -n myservice --daemon # Restart specific daemon
  launchd-mgmt start -n myservice            # Start a stopped service
  launchd-mgmt stop -n myservice             # Stop a running service
  launchd-mgmt info -n myservice             # Show service details

Environment:
  LAUNCHD_FILTER    Default filter pattern for service names
""",
    )

    parser.add_argument(
        "-f", "--filter",
        default=os.environ.get("LAUNCHD_FILTER", ""),
        help="Filter services by pattern (default: $LAUNCHD_FILTER or none)",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    # list command
    list_parser = subparsers.add_parser("list", aliases=["ls"], help="List services")
    list_parser.add_argument(
        "-t", "--type",
        choices=["all", "agents", "daemons"],
        default="all",
        help="Type of services to list",
    )
    list_parser.add_argument(
        "-u", "--unhealthy",
        action="store_true",
        help="Show only unhealthy services",
    )
    list_parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Show verbose output with PID and exit codes",
    )
    list_parser.set_defaults(func=cmd_list)

    # status command
    status_parser = subparsers.add_parser("status", aliases=["st"], help="Show unhealthy services")
    status_parser.add_argument(
        "-t", "--type",
        choices=["all", "agents", "daemons"],
        default="all",
        help="Type of services to check",
    )
    status_parser.set_defaults(func=cmd_status)

    # restart command
    restart_parser = subparsers.add_parser("restart", aliases=["rs"], help="Restart services")
    restart_parser.add_argument(
        "-n", "--name",
        help="Specific service name to restart",
    )
    restart_parser.add_argument(
        "-t", "--type",
        choices=["all", "agents", "daemons"],
        default="all",
        help="Type of services to restart (when no name specified)",
    )
    restart_parser.add_argument(
        "-d", "--daemon",
        action="store_true",
        help="Treat named service as daemon (requires sudo)",
    )
    restart_parser.set_defaults(func=cmd_restart)

    # start command
    start_parser = subparsers.add_parser("start", help="Start a service")
    start_parser.add_argument(
        "-n", "--name",
        required=True,
        help="Service name to start",
    )
    start_parser.add_argument(
        "-d", "--daemon",
        action="store_true",
        help="Treat as daemon (requires sudo)",
    )
    start_parser.set_defaults(func=cmd_start)

    # stop command
    stop_parser = subparsers.add_parser("stop", help="Stop a service")
    stop_parser.add_argument(
        "-n", "--name",
        required=True,
        help="Service name to stop",
    )
    stop_parser.add_argument(
        "-d", "--daemon",
        action="store_true",
        help="Treat as daemon (requires sudo)",
    )
    stop_parser.set_defaults(func=cmd_stop)

    # info command
    info_parser = subparsers.add_parser("info", help="Show service details")
    info_parser.add_argument(
        "-n", "--name",
        required=True,
        help="Service name",
    )
    info_parser.add_argument(
        "-d", "--daemon",
        action="store_true",
        help="Treat as daemon (requires sudo)",
    )
    info_parser.set_defaults(func=cmd_info)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
