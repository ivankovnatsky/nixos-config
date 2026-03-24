#!/usr/bin/env python3
"""
launchd-mgmt - A general management tool for macOS launchd services.

Provides unified interface for managing launchd agents (user-level) and
daemons (system-level) with filtering, health checking, and bulk operations.
"""

import os
import plistlib
import subprocess
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Optional

import click


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


def run_cmd(
    cmd: list[str], capture: bool = True, check: bool = True
) -> subprocess.CompletedProcess:
    try:
        return subprocess.run(
            cmd,
            capture_output=capture,
            text=True,
            check=check,
        )
    except subprocess.CalledProcessError as e:
        if capture:
            click.echo(f"Error: {e.stderr}", err=True)
        raise


def run_sudo_cmd(
    cmd: list[str], capture: bool = True, check: bool = True
) -> subprocess.CompletedProcess:
    return run_cmd(["sudo"] + cmd, capture=capture, check=check)


def get_uid() -> int:
    return os.getuid()


def parse_launchctl_list(output: str, service_type: ServiceType) -> list[Service]:
    services = []
    for line in output.strip().split("\n")[1:]:
        parts = line.split("\t")
        if len(parts) >= 3:
            pid_str, exit_code_str, name = parts[0], parts[1], parts[2]
            pid = int(pid_str) if pid_str != "-" else None
            exit_code = int(exit_code_str) if exit_code_str != "-" else None
            services.append(Service(name, pid, exit_code, service_type))
    return services


def list_agents(pattern: Optional[str] = None) -> list[Service]:
    result = run_cmd(["launchctl", "list"])
    services = parse_launchctl_list(result.stdout, ServiceType.AGENT)
    if pattern:
        services = [s for s in services if pattern in s.name]
    return services


def list_daemons(pattern: Optional[str] = None) -> list[Service]:
    result = run_sudo_cmd(["launchctl", "list"])
    services = parse_launchctl_list(result.stdout, ServiceType.DAEMON)
    if pattern:
        services = [s for s in services if pattern in s.name]
    return services


def format_service(svc: Service, verbose: bool = False) -> str:
    status = "●" if svc.is_running else "○"
    health = "✓" if svc.is_healthy else "✗"
    pid_str = str(svc.pid) if svc.pid else "-"
    exit_str = str(svc.exit_code) if svc.exit_code is not None else "-"

    if verbose:
        return f"{status} {health}  {svc.name:<50} PID: {pid_str:<8} Exit: {exit_str}"
    return f"{status} {health}  {svc.name}"


def restart_service(name: str, service_type: ServiceType) -> bool:
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
        click.echo(f"  Failed to restart {name}: {e.stderr}", err=True)
        return False


def get_plist_path(name: str, service_type: ServiceType) -> Optional[str]:
    if service_type == ServiceType.AGENT:
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
        click.echo(f"  Failed to stop {name}: {e.stderr}", err=True)
        return False


def start_service(name: str, service_type: ServiceType) -> bool:
    uid = get_uid()
    plist_path = get_plist_path(name, service_type)

    if not plist_path:
        click.echo(f"  Could not find plist for {name}", err=True)
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
        click.echo(f"  Failed to start {name}: {e.stderr}", err=True)
        return False


SERVICE_TYPE = click.Choice(["all", "agents", "daemons"])

ALIASES = {
    "ls": "list",
    "st": "status",
    "rs": "restart",
}


class AliasGroup(click.Group):
    def get_command(self, ctx, cmd_name):
        cmd_name = ALIASES.get(cmd_name, cmd_name)
        return super().get_command(ctx, cmd_name)

    def resolve_command(self, ctx, args):
        if args and args[0] in ALIASES:
            args[0] = ALIASES[args[0]]
        return super().resolve_command(ctx, args)


@click.group(cls=AliasGroup)
@click.option(
    "-f",
    "--filter",
    "pattern",
    default=lambda: os.environ.get("LAUNCHD_FILTER", ""),
    help="Filter services by pattern",
)
@click.pass_context
def cli(ctx, pattern):
    """Manage macOS launchd services (agents and daemons)."""
    ctx.ensure_object(dict)
    ctx.obj["pattern"] = pattern


@cli.command("list")
@click.option(
    "-t",
    "--type",
    "svc_type",
    type=SERVICE_TYPE,
    default="all",
    help="Type of services to list",
)
@click.option("-u", "--unhealthy", is_flag=True, help="Show only unhealthy services")
@click.option(
    "-v", "--verbose", is_flag=True, help="Show verbose output with PID and exit codes"
)
@click.pass_context
def cmd_list(ctx, svc_type, unhealthy, verbose):
    """List services."""
    pattern = ctx.obj["pattern"]
    show_agents = svc_type in ("all", "agents")
    show_daemons = svc_type in ("all", "daemons")

    if show_agents:
        click.echo("=== User Agents ===")
        agents = list_agents(pattern)
        if unhealthy:
            agents = [a for a in agents if not a.is_healthy]
        if agents:
            for svc in sorted(agents, key=lambda s: s.name):
                click.echo(format_service(svc, verbose))
        else:
            click.echo("None found" if not unhealthy else "All healthy")
        click.echo()

    if show_daemons:
        click.echo("=== System Daemons ===")
        daemons = list_daemons(pattern)
        if unhealthy:
            daemons = [d for d in daemons if not d.is_healthy]
        if daemons:
            for svc in sorted(daemons, key=lambda s: s.name):
                click.echo(format_service(svc, verbose))
        else:
            click.echo("None found" if not unhealthy else "All healthy")


@cli.command()
@click.option("-n", "--name", default=None, help="Specific service name to restart")
@click.option(
    "-t",
    "--type",
    "svc_type",
    type=SERVICE_TYPE,
    default="all",
    help="Type of services to restart",
)
@click.option("-u", "--unhealthy", is_flag=True, help="Restart all unhealthy services")
@click.option(
    "-d", "--daemon", is_flag=True, help="Treat named service as daemon (requires sudo)"
)
@click.pass_context
def restart(ctx, name, svc_type, unhealthy, daemon):
    """Restart services."""
    pattern = ctx.obj["pattern"]

    if name:
        svc_type_enum = ServiceType.DAEMON if daemon else ServiceType.AGENT
        click.echo(f"Restarting {svc_type_enum.value}: {name}")
        success = restart_service(name, svc_type_enum)
        raise SystemExit(0 if success else 1)

    if not unhealthy:
        click.echo(
            "Error: specify --unhealthy to restart all unhealthy services, or -n to restart a specific service",
            err=True,
        )
        raise SystemExit(1)

    restart_agents = svc_type in ("all", "agents")
    restart_daemons = svc_type in ("all", "daemons")
    failed = 0

    if restart_agents:
        click.echo("Checking user agents...")
        agents = list_agents(pattern)
        unhealthy_agents = [a for a in agents if not a.is_healthy]
        if unhealthy_agents:
            click.echo("Restarting unhealthy agents:")
            for svc in unhealthy_agents:
                click.echo(f"  → {svc.name}")
                if not restart_service(svc.name, ServiceType.AGENT):
                    failed += 1
        else:
            click.echo("All agents are healthy (exit code 0)")
        click.echo()

    if restart_daemons:
        click.echo("Checking system daemons (requires sudo)...")
        daemons = list_daemons(pattern)
        unhealthy_daemons = [d for d in daemons if not d.is_healthy]
        if unhealthy_daemons:
            click.echo("Restarting unhealthy daemons:")
            for svc in unhealthy_daemons:
                click.echo(f"  → {svc.name}")
                if not restart_service(svc.name, ServiceType.DAEMON):
                    failed += 1
        else:
            click.echo("All daemons are healthy (exit code 0)")

    raise SystemExit(1 if failed > 0 else 0)


@cli.command()
@click.option("-n", "--name", required=True, help="Service name to stop")
@click.option("-d", "--daemon", is_flag=True, help="Treat as daemon (requires sudo)")
def stop(name, daemon):
    """Stop a service."""
    svc_type = ServiceType.DAEMON if daemon else ServiceType.AGENT
    click.echo(f"Stopping {svc_type.value}: {name}")
    success = stop_service(name, svc_type)
    raise SystemExit(0 if success else 1)


@cli.command()
@click.option("-n", "--name", required=True, help="Service name to start")
@click.option("-d", "--daemon", is_flag=True, help="Treat as daemon (requires sudo)")
def start(name, daemon):
    """Start a service."""
    svc_type = ServiceType.DAEMON if daemon else ServiceType.AGENT
    click.echo(f"Starting {svc_type.value}: {name}")
    success = start_service(name, svc_type)
    raise SystemExit(0 if success else 1)


@cli.command()
@click.option(
    "-t",
    "--type",
    "svc_type",
    type=SERVICE_TYPE,
    default="all",
    help="Type of services to check",
)
@click.pass_context
def status(ctx, svc_type):
    """Show unhealthy services."""
    pattern = ctx.obj["pattern"]
    show_agents = svc_type in ("all", "agents")
    show_daemons = svc_type in ("all", "daemons")

    click.echo("=== Unhealthy Services ===\n")

    if show_agents:
        click.echo("User Agents:")
        agents = list_agents(pattern)
        unhealthy_agents = [a for a in agents if not a.is_healthy]
        if unhealthy_agents:
            for svc in sorted(unhealthy_agents, key=lambda s: s.name):
                click.echo(f"  {format_service(svc, verbose=True)}")
        else:
            click.echo("  All healthy")
        click.echo()

    if show_daemons:
        click.echo("System Daemons:")
        daemons = list_daemons(pattern)
        unhealthy_daemons = [d for d in daemons if not d.is_healthy]
        if unhealthy_daemons:
            for svc in sorted(unhealthy_daemons, key=lambda s: s.name):
                click.echo(f"  {format_service(svc, verbose=True)}")
        else:
            click.echo("  All healthy")


@cli.command()
@click.option("-n", "--name", required=True, help="Service name")
@click.option("-d", "--daemon", is_flag=True, help="Treat as daemon (requires sudo)")
def info(name, daemon):
    """Show detailed info about a service."""
    uid = get_uid()
    svc_type = ServiceType.DAEMON if daemon else ServiceType.AGENT

    if svc_type == ServiceType.AGENT:
        target = f"gui/{uid}/{name}"
        cmd = ["launchctl", "print", target]
    else:
        target = f"system/{name}"
        cmd = ["sudo", "launchctl", "print", target]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        click.echo(result.stdout)
    except subprocess.CalledProcessError as e:
        click.echo(f"Error: {e.stderr}", err=True)
        raise SystemExit(1)


def find_orphaned_plists(
    pattern: Optional[str] = None,
) -> list[tuple[str, str, ServiceType]]:
    """Find plist files whose nix store paths no longer exist.

    Returns list of (label, plist_path, service_type) tuples.
    """
    orphans = []

    scan_dirs = [
        (Path.home() / "Library" / "LaunchAgents", ServiceType.AGENT),
        (Path("/Library/LaunchDaemons"), ServiceType.DAEMON),
    ]

    for directory, svc_type in scan_dirs:
        if not directory.exists():
            continue
        for plist_file in sorted(directory.glob("com.ivankovnatsky.*.plist")):
            label = plist_file.stem
            if pattern and pattern not in label:
                continue
            try:
                with open(plist_file, "rb") as f:
                    plist = plistlib.load(f)
            except Exception:
                continue

            program_args = plist.get("ProgramArguments", [])
            program = plist.get("Program")

            paths_to_check = []
            if program:
                paths_to_check.append(program)
            for arg in program_args:
                if "/nix/store/" in arg:
                    for part in arg.split("&&"):
                        part = part.strip()
                        if "/nix/store/" in part:
                            tokens = part.split()
                            for token in tokens:
                                if token.startswith("/nix/store/"):
                                    paths_to_check.append(token)

            for path in paths_to_check:
                if path.startswith("/nix/store/") and not os.path.exists(path):
                    orphans.append((label, str(plist_file), svc_type))
                    break

    return orphans


@cli.command()
@click.option(
    "--dry-run", is_flag=True, help="Show orphans without removing them"
)
@click.pass_context
def clean(ctx, dry_run):
    """Remove orphaned plists with broken nix store paths."""
    pattern = ctx.obj["pattern"]
    orphans = find_orphaned_plists(pattern)

    if not orphans:
        click.echo("No orphaned plists found.")
        raise SystemExit(0)

    click.echo(f"Found {len(orphans)} orphaned plist(s):\n")
    for label, plist_path, svc_type in orphans:
        click.echo(f"  {label}")
        click.echo(f"    {plist_path}")

    if dry_run:
        click.echo("\nDry run — no changes made.")
        raise SystemExit(0)

    click.echo()
    failed = 0
    uid = get_uid()
    for label, plist_path, svc_type in orphans:
        click.echo(f"Cleaning {label}...")

        # Try to unload/bootout first
        if svc_type == ServiceType.AGENT:
            target = f"gui/{uid}/{label}"
            bootout_cmd = ["launchctl", "bootout", target]
        else:
            target = f"system/{label}"
            bootout_cmd = ["sudo", "launchctl", "bootout", target]

        try:
            subprocess.run(bootout_cmd, capture_output=True, text=True, check=False)
        except Exception:
            pass

        try:
            os.remove(plist_path)
            click.echo(f"  Removed {plist_path}")
        except OSError as e:
            click.echo(f"  Failed to remove {plist_path}: {e}", err=True)
            failed += 1

    click.echo(f"\nCleaned {len(orphans) - failed} orphan(s).")
    raise SystemExit(1 if failed > 0 else 0)


if __name__ == "__main__":
    cli()
