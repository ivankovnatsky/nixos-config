#!/usr/bin/env python3
"""Manage homelab machines (power on/off Mini)."""

import argparse
import subprocess
import sys
import time

MINI_IP = "192.168.50.4"
MINI_USER = "ivan"
RETRY_INTERVAL = 5  # seconds between retries
SERVICE_CHECK_TIMEOUT = 60  # max seconds to wait for services
SSH_TIMEOUT = 10  # seconds for SSH connection timeout


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
        return result.stdout.strip() == "200"
    return result.returncode == 0


def wait_for_services() -> bool:
    """Wait for all services to be ready."""
    print("Waiting for services to come up...")
    start_time = time.time()
    ready_services: set[str] = set()

    while time.time() - start_time < SERVICE_CHECK_TIMEOUT:
        pending = []
        for name, command in SERVICES_TO_CHECK:
            if name in ready_services:
                continue
            if check_service(name, command):
                print(f"  ✓ {name} is ready")
                ready_services.add(name)
            else:
                pending.append(name)

        if not pending:
            print("All services are ready!")
            return True

        print(f"  Waiting for: {', '.join(pending)}...")
        time.sleep(RETRY_INTERVAL)

    print("Timeout waiting for services.")
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
        print(f"Waiting for network... (attempt {attempt})")
        time.sleep(RETRY_INTERVAL)
        attempt += 1


def power_on() -> int:
    """Unlock and connect to Mini."""
    # Wait for network connectivity before attempting SSH
    wait_for_network()

    print(f"Attempting to unlock Mini at {MINI_IP}...")

    # First attempt - this handles the FileVault unlock prompt
    # Note: FileVault unlock always closes the connection after success,
    # so we can't rely on return code here.
    ssh_run("echo 'Connected'")

    # Wait for system to boot after FileVault unlock
    print("Waiting for Mini to boot...")
    time.sleep(RETRY_INTERVAL)

    # Now wait for SSH to be ready with key-based auth
    attempt = 1
    while True:
        result = ssh_run("echo 'Connected'", batch_mode=True, capture_output=True)
        if result.returncode == 0:
            break
        print(f"Waiting for SSH... (attempt {attempt})")
        time.sleep(RETRY_INTERVAL)
        attempt += 1

    print("Mini is now unlocked and accessible.")

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
        print("Skipping Screen Sharing.")

    read_tty("Press Enter after unlocking Mini via Screen Sharing... ")
    subprocess.run(["dns", MINI_IP], check=False)

    wait_for_services()

    print("\nMonitor status:")
    try:
        subprocess.run(
            ["uptime-kuma-mgmt", "list", "--base-url", f"http://{MINI_IP}:3001"],
            check=False,
        )
    except FileNotFoundError:
        print("  (uptime-kuma-mgmt not available)")
    return 0


def is_mini_up() -> bool:
    """Check if Mini is currently accessible."""
    result = ssh_run("echo 'ok'", timeout=3, batch_mode=True, capture_output=True)
    return result.returncode == 0


def power_off() -> int:
    """Power off Mini."""
    print("Clearing local DNS settings before shutting down Mini...")
    result = subprocess.run(["dns", "clear"], check=False)
    if result.returncode != 0:
        print("Warning: Failed to clear DNS settings")

    print(f"Shutting down Mini at {MINI_IP}...")
    result = ssh_run("sudo shutdown -h now")

    if result.returncode != 0:
        print("Failed to shutdown Mini.")
        return 1

    print("Mini shutdown initiated.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Manage homelab machines. Run without arguments to toggle Mini on/off."
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    subparsers.add_parser("on", help="Power on and unlock Mini")
    subparsers.add_parser("off", help="Power off Mini")

    args = parser.parse_args()

    if args.command == "on":
        return power_on()
    elif args.command == "off":
        return power_off()
    else:
        # Toggle: check current state and switch
        print("Checking Mini status...")
        if is_mini_up():
            print("Mini is up, powering off...")
            return power_off()
        else:
            print("Mini is down, powering on...")
            return power_on()


if __name__ == "__main__":
    sys.exit(main())
