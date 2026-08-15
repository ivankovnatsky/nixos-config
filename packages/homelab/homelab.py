#!/usr/bin/env python3
"""Manage homelab machines (power on/off, Wake-on-LAN, FileVault unlock)."""

import socket
import subprocess
import sys
import time

import click

MACHINES = {
    "a3": {
        "ip": "192.168.50.6",
        "mac": "34:5a:60:eb:04:8b",
        "user": "ivan",
    },
    "mini": {
        "ip": "192.168.50.4",
        "mac": None,
        "user": "ivan",
    },
}

MINI_IP = MACHINES["mini"]["ip"]
MINI_USER = MACHINES["mini"]["user"]
A3_IP = MACHINES["a3"]["ip"]
A3_MAC = MACHINES["a3"]["mac"]

RETRY_INTERVAL = 2  # seconds between retries
SERVICE_CHECK_TIMEOUT = 60  # max seconds to wait for services
SSH_TIMEOUT = 10  # seconds for SSH connection timeout
MAX_UNLOCK_ATTEMPTS = 3  # max FileVault unlock attempts


def send_wol_packet(mac: str, broadcast_ips: list[str] | None = None, port: int = 9) -> None:
    """Construct and broadcast a Wake-on-LAN magic packet."""
    clean_mac = mac.replace(":", "").replace("-", "").replace(".", "")
    if len(clean_mac) != 12:
        raise ValueError(f"Invalid MAC address: {mac}")
    packet = bytes.fromhex("F" * 12 + clean_mac * 16)

    targets = broadcast_ips or ["192.168.50.255", "255.255.255.255"]
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        for target in targets:
            try:
                s.sendto(packet, (target, port))
            except OSError as e:
                click.echo(f"  Warning: failed to send to {target}:{port}: {e}", err=True)


def is_host_pingable(ip: str, timeout: int = 1) -> bool:
    """Check if host responds to ICMP ping."""
    result = subprocess.run(
        ["ping", "-c", "1", "-W", str(timeout), ip],
        capture_output=True,
    )
    return result.returncode == 0


def is_ssh_accessible(user: str, ip: str, timeout: int = 3) -> bool:
    """Check if host accepts SSH connections."""
    result = subprocess.run(
        [
            "ssh",
            "-o",
            f"ConnectTimeout={timeout}",
            "-o",
            "BatchMode=yes",
            f"{user}@{ip}",
            "echo ok",
        ],
        capture_output=True,
    )
    return result.returncode == 0


def ssh_run(
    command: str,
    ip: str = MINI_IP,
    user: str = MINI_USER,
    timeout: int = SSH_TIMEOUT,
    batch_mode: bool = False,
    capture_output: bool = False,
) -> subprocess.CompletedProcess[str]:
    """Run SSH command on target host with standard options."""
    ssh_args = [
        "ssh",
        "-o",
        f"ConnectTimeout={timeout}",
    ]
    if batch_mode:
        ssh_args.extend(["-o", "BatchMode=yes"])
    ssh_args.append(f"{user}@{ip}")
    ssh_args.append(command)
    return subprocess.run(
        ssh_args, capture_output=capture_output, text=True, check=False
    )


SERVICES_TO_CHECK = [
    ("DNS", f"dig @{MINI_IP} google.com +short +timeout=2"),
    (
        "Uptime Kuma",
        f"curl -s -o /dev/null -w '%{{http_code}}' --connect-timeout 2 http://{MINI_IP}:3001",
    ),
]


def read_tty(prompt: str) -> str:
    """Read from /dev/tty to avoid stdin issues after SSH."""
    sys.stdout.write(prompt)
    sys.stdout.flush()
    try:
        with open("/dev/tty", "r") as tty:
            return tty.readline().strip()
    except OSError:
        return input(prompt).strip()


def check_service(name: str, command: str) -> bool:
    """Check if a service is responding."""
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if name == "DNS":
        return result.returncode == 0 and result.stdout.strip() != ""
    elif name == "Uptime Kuma":
        code = result.stdout.strip()
        return code in ("200", "302")
    return result.returncode == 0


def wait_for_services() -> bool:
    """Wait for all Mini services to be ready."""
    click.echo("Waiting for services to come up...")
    start_time = time.time()
    ready_services: set[str] = set()

    while time.time() - start_time < SERVICE_CHECK_TIMEOUT:
        pending = []
        for name, command in SERVICES_TO_CHECK:
            if name in ready_services:
                continue
            if check_service(name, command):
                click.echo(f"  ✓ {name} is ready")
                ready_services.add(name)
            else:
                pending.append(name)

        if not pending:
            click.echo("All services are ready!")
            return True

        click.echo(f"  Waiting for: {', '.join(pending)}...")
        time.sleep(RETRY_INTERVAL)

    click.echo("Timeout waiting for services.")
    return False


def wait_for_host(ip: str, timeout: int = 60, interval: int = 2) -> bool:
    """Poll ping until host comes online."""
    start_time = time.time()
    attempt = 1
    while time.time() - start_time < timeout:
        if is_host_pingable(ip):
            return True
        click.echo(f"  Waiting for {ip} to respond... (attempt {attempt})")
        time.sleep(interval)
        attempt += 1
    return False


def is_filevault_locked() -> bool:
    """Check if Mini is still in FileVault lock state."""
    result = ssh_run("echo ok", timeout=5, batch_mode=True, capture_output=True)
    if result.returncode == 0:
        return False
    combined = result.stdout + result.stderr
    return "locked" in combined.lower()


def power_on_mini() -> int:
    """Unlock and connect to Mini."""
    if not wait_for_host(MINI_IP, timeout=30):
        click.echo(f"Error: Mini ({MINI_IP}) is unreachable on network.")
        return 1

    for attempt in range(1, MAX_UNLOCK_ATTEMPTS + 1):
        if attempt > 1:
            click.echo(
                f"\nRetrying unlock... (attempt {attempt}/{MAX_UNLOCK_ATTEMPTS})"
            )
        else:
            click.echo(f"Attempting to unlock Mini at {MINI_IP}...")

        ssh_run("echo 'Connected'")
        time.sleep(2)

        if not is_filevault_locked():
            break

        click.echo("Unlock failed (wrong password?).")
    else:
        click.echo(f"Failed to unlock after {MAX_UNLOCK_ATTEMPTS} attempts.")
        return 1

    click.echo("Waiting for Mini to boot...")
    time.sleep(RETRY_INTERVAL)

    attempt = 1
    while True:
        result = ssh_run("echo 'Connected'", batch_mode=True, capture_output=True)
        if result.returncode == 0:
            break
        click.echo(f"Waiting for SSH... (attempt {attempt})")
        time.sleep(RETRY_INTERVAL)
        attempt += 1

    click.echo("Mini is now unlocked and accessible.")

    response = read_tty("Open Screen Sharing? [Y/n] ")
    if response.lower() not in ("n", "no"):
        subprocess.run(
            [
                "osascript",
                "-e",
                f"""
                tell application "Screen Sharing"
                    activate
                    open location "vnc://{MINI_USER}@{MINI_IP}"
                end tell

                delay 2
                tell application "System Events"
                    tell process "Screen Sharing"
                        set frontmost to true
                        key code 125
                        keystroke return
                    end tell
                end tell
                """,
            ],
            check=False,
        )
    else:
        click.echo("Skipping Screen Sharing.")

    read_tty("Press Enter after unlocking Mini via Screen Sharing... ")
    subprocess.run(["dns", MINI_IP], check=False)

    wait_for_services()

    click.echo("\nMonitor status:")
    try:
        subprocess.run(
            ["uptime-kuma-mgmt", "list", "--base-url", f"http://{MINI_IP}:3001"],
            check=False,
        )
    except FileNotFoundError:
        click.echo("  (uptime-kuma-mgmt not available)")
    return 0


def power_off_machine(target: str) -> int:
    """Power off a homelab machine (mini or a3)."""
    machine_info = MACHINES.get(target.lower())
    if not machine_info:
        click.echo(f"Unknown machine '{target}'. Available: {', '.join(MACHINES.keys())}")
        return 1

    ip = machine_info["ip"]
    user = machine_info["user"]

    if target.lower() == "mini":
        click.echo("Clearing local DNS settings before shutting down Mini...")
        subprocess.run(["dns", "clear"], check=False)

    click.echo(f"Shutting down {target} at {ip}...")
    ssh_run("sudo poweroff" if target.lower() == "a3" else "sudo shutdown -h now", ip=ip, user=user)
    click.echo(f"{target} shutdown initiated.")
    return 0


@click.group(invoke_without_command=True)
@click.pass_context
def main(ctx: click.Context) -> None:
    """Manage homelab machines (power on/off, Wake-on-LAN, status)."""
    if ctx.invoked_subcommand is None:
        ctx.invoke(status)


@main.command()
@click.argument("machine", default="a3", type=click.Choice(list(MACHINES.keys()), case_sensitive=False))
@click.option("--mac", default=None, help="Custom MAC address to send packet to.")
@click.option("--broadcast", "-b", multiple=True, help="Broadcast IP addresses to send packet to.")
@click.option("--wait/--no-wait", "-w", default=True, help="Wait for host to respond to ping.")
@click.option("--timeout", "-t", default=60, type=int, help="Timeout in seconds when waiting for host.")
def wol(machine: str, mac: str | None, broadcast: tuple[str, ...], wait: bool, timeout: int) -> None:
    """Send Wake-on-LAN magic packet to wake a machine."""
    m_info = MACHINES.get(machine.lower(), {})
    target_mac = mac or m_info.get("mac")
    target_ip = m_info.get("ip")

    if not target_mac:
        click.echo(f"Error: No MAC address known for machine '{machine}'. Use --mac.")
        sys.exit(1)

    click.echo(f"Sending WoL magic packet to {machine} ({target_mac})...")
    send_wol_packet(target_mac, list(broadcast) if broadcast else None)
    click.echo("✓ Magic packet broadcasted.")

    if wait and target_ip:
        click.echo(f"Waiting for {machine} ({target_ip}) to come online...")
        if wait_for_host(target_ip, timeout=timeout):
            click.echo(f"✓ {machine} ({target_ip}) is UP and responding to ping!")
        else:
            click.echo(f"✗ Timeout waiting for {machine} ({target_ip}) after {timeout}s.")
            sys.exit(1)


@main.command()
def status() -> None:
    """Show live status of all homelab machines."""
    click.echo("Homelab Machines Status:")
    for name, info in MACHINES.items():
        ip = info["ip"]
        user = info["user"]
        mac_str = f" ({info['mac']})" if info.get("mac") else ""
        ping_ok = is_host_pingable(ip)
        if ping_ok:
            ssh_ok = is_ssh_accessible(user, ip)
            ssh_str = "✓ SSH ready" if ssh_ok else "✗ SSH locked/down"
            click.echo(f"  ● {name:<6} {ip:<15}{mac_str:<22} : UP ({ssh_str})")
        else:
            click.echo(f"  ○ {name:<6} {ip:<15}{mac_str:<22} : OFFLINE")


@main.command()
def on() -> None:
    """Power on and unlock Mini."""
    sys.exit(power_on_mini())


@main.command()
@click.argument("machine", default="mini", type=click.Choice(list(MACHINES.keys()), case_sensitive=False))
def off(machine: str) -> None:
    """Power off a machine (default: mini)."""
    sys.exit(power_off_machine(machine))


if __name__ == "__main__":
    main(prog_name="homelab")
