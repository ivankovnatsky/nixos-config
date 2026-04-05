#!/usr/bin/env python3
"""Manage homelab machines (power on/off Mini)."""

import subprocess
import sys
import time

import click

MINI_IP = "192.168.50.4"
MINI_USER = "ivan"
RETRY_INTERVAL = 5  # seconds between retries
SERVICE_CHECK_TIMEOUT = 60  # max seconds to wait for services
SSH_TIMEOUT = 10  # seconds for SSH connection timeout
MAX_UNLOCK_ATTEMPTS = 3  # max FileVault unlock attempts


def ssh_run(
    command: str,
    timeout: int = SSH_TIMEOUT,
    batch_mode: bool = False,
    capture_output: bool = False,
) -> subprocess.CompletedProcess[str]:
    """Run SSH command on Mini with standard options."""
    ssh_args = [
        "ssh",
        "-o",
        f"ConnectTimeout={timeout}",
    ]
    if batch_mode:
        ssh_args.extend(["-o", "BatchMode=yes"])
    ssh_args.append(f"{MINI_USER}@{MINI_IP}")
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
    with open("/dev/tty", "r") as tty:
        return tty.readline().strip()


def check_service(name: str, command: str) -> bool:
    """Check if a service is responding."""
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if name == "DNS":
        return result.returncode == 0 and result.stdout.strip() != ""
    elif name == "Uptime Kuma":
        # Uptime Kuma returns 302 redirect to login page when ready
        code = result.stdout.strip()
        return code in ("200", "302")
    return result.returncode == 0


def wait_for_services() -> bool:
    """Wait for all services to be ready."""
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


def wait_for_network() -> None:
    """Wait until Mini is reachable on the network."""
    attempt = 1
    while True:
        result = subprocess.run(
            ["ping", "-c", "1", "-W", "1", MINI_IP],
            capture_output=True,
        )
        if result.returncode == 0:
            return
        click.echo(f"Waiting for network... (attempt {attempt})")
        time.sleep(RETRY_INTERVAL)
        attempt += 1


def is_filevault_locked() -> bool:
    """Check if Mini is still in FileVault lock state."""
    result = ssh_run("echo ok", timeout=5, batch_mode=True, capture_output=True)
    if result.returncode == 0:
        return False
    combined = result.stdout + result.stderr
    return "locked" in combined.lower()


def power_on() -> int:
    """Unlock and connect to Mini."""
    # Wait for network connectivity before attempting SSH
    wait_for_network()

    # FileVault unlock with retry on wrong password
    for attempt in range(1, MAX_UNLOCK_ATTEMPTS + 1):
        if attempt > 1:
            click.echo(
                f"\nRetrying unlock... (attempt {attempt}/{MAX_UNLOCK_ATTEMPTS})"
            )
        else:
            click.echo(f"Attempting to unlock Mini at {MINI_IP}...")

        # Interactive SSH for FileVault unlock prompt
        # Note: FileVault unlock always closes the connection after success,
        # so we can't rely on return code here.
        ssh_run("echo 'Connected'")

        # Brief wait to let the system process the unlock
        time.sleep(2)

        # Check if system is still in FileVault lock state
        if not is_filevault_locked():
            break

        click.echo("Unlock failed (wrong password?).")
    else:
        click.echo(f"Failed to unlock after {MAX_UNLOCK_ATTEMPTS} attempts.")
        return 1

    # Wait for system to boot after FileVault unlock
    click.echo("Waiting for Mini to boot...")
    time.sleep(RETRY_INTERVAL)

    # Now wait for SSH to be ready with key-based auth
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

                -- Wait for the Screen Sharing Type dialog, select High Quality, and press Enter
                delay 2
                tell application "System Events"
                    tell process "Screen Sharing"
                        set frontmost to true
                        key code 125  -- down arrow to select High Quality
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


def is_mini_up() -> bool:
    """Check if Mini is currently accessible."""
    result = ssh_run("echo 'ok'", timeout=3, batch_mode=True, capture_output=True)
    return result.returncode == 0


def power_off() -> int:
    """Power off Mini."""
    click.echo("Clearing local DNS settings before shutting down Mini...")
    result = subprocess.run(["dns", "clear"], check=False)
    if result.returncode != 0:
        click.echo("Warning: Failed to clear DNS settings")

    click.echo(f"Shutting down Mini at {MINI_IP}...")
    # Don't check return code - shutdown closes the connection which causes
    # SSH to return non-zero (255), but that's expected behavior
    ssh_run("sudo shutdown -h now")

    click.echo("Mini shutdown initiated.")
    return 0


@click.group(invoke_without_command=True)
@click.pass_context
def main(ctx: click.Context) -> None:
    """Manage homelab machines. Run without arguments to toggle Mini on/off."""
    if ctx.invoked_subcommand is None:
        # Toggle: check current state and switch
        click.echo("Checking Mini status...")
        if is_mini_up():
            click.echo("Mini is up, powering off...")
            sys.exit(power_off())
        else:
            click.echo("Mini is down, powering on...")
            sys.exit(power_on())


@main.command()
def on() -> None:
    """Power on and unlock Mini."""
    sys.exit(power_on())


@main.command()
def off() -> None:
    """Power off Mini."""
    sys.exit(power_off())


if __name__ == "__main__":
    main()
