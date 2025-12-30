#!/usr/bin/env python3
"""Manage homelab machines (power on/off Mini)."""

import argparse
import subprocess
import sys
import time
import webbrowser

MINI_IP = "192.168.50.4"
MINI_USER = "ivan"
RETRY_INTERVAL = 5  # seconds between retries


def read_tty(prompt: str) -> str:
    """Read from /dev/tty to avoid stdin issues after SSH."""
    sys.stdout.write(prompt)
    sys.stdout.flush()
    with open("/dev/tty", "r") as tty:
        return tty.readline().strip()


def power_on() -> int:
    """Unlock and connect to Mini."""
    print(f"Attempting to unlock Mini at {MINI_IP}...")

    # First attempt - this handles the unlock prompt
    result = subprocess.run(
        ["ssh", "-o", "ConnectTimeout=10", f"{MINI_USER}@{MINI_IP}", "echo 'Connected'"],
        check=False,
    )

    # If first attempt failed, retry until successful
    if result.returncode != 0:
        print("Waiting for Mini to become available...")
        attempt = 1
        while True:
            print(f"Retry attempt {attempt}...")
            time.sleep(RETRY_INTERVAL)
            result = subprocess.run(
                ["ssh", "-o", "ConnectTimeout=10", f"{MINI_USER}@{MINI_IP}", "echo 'Connected'"],
                check=False,
            )
            if result.returncode == 0:
                break
            attempt += 1

    print("Mini is now unlocked and accessible.")

    response = read_tty("Open Screen Sharing? [Y/n] ")
    if response.lower() not in ("n", "no"):
        subprocess.run(
            [
                "osascript",
                "-e",
                f'''
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
                ''',
            ],
            check=False,
        )
    else:
        print("Skipping Screen Sharing.")

    read_tty("Press Enter after unlocking Mini via Screen Sharing... ")
    subprocess.run(["dns", MINI_IP], check=False)

    webbrowser.open(f"http://{MINI_IP}:3001")
    return 0


def power_off() -> int:
    """Power off Mini."""
    print("Clearing local DNS settings before shutting down Mini...")
    result = subprocess.run(["dns", "clear"], check=False)
    if result.returncode != 0:
        print("Warning: Failed to clear DNS settings")

    print(f"Shutting down Mini at {MINI_IP}...")
    result = subprocess.run(
        ["ssh", f"{MINI_USER}@{MINI_IP}", "sudo", "shutdown", "-h", "now"],
        check=False,
    )

    if result.returncode != 0:
        print("Failed to shutdown Mini.")
        return 1

    print("Mini shutdown initiated.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Manage homelab machines")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    subparsers.add_parser("on", help="Power on and unlock Mini")
    subparsers.add_parser("off", help="Power off Mini")

    args = parser.parse_args()

    if args.command == "on":
        return power_on()
    elif args.command == "off":
        return power_off()
    else:
        parser.print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())
