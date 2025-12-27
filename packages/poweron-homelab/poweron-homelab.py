#!/usr/bin/env python3
"""Remotely unlock and connect to homelab Mini."""

import subprocess
import sys
import webbrowser

MINI_IP = "192.168.50.4"
MINI_USER = "ivan"


def read_tty(prompt: str) -> str:
    """Read from /dev/tty to avoid stdin issues after SSH."""
    sys.stdout.write(prompt)
    sys.stdout.flush()
    with open("/dev/tty", "r") as tty:
        return tty.readline().strip()


def main() -> int:
    print(f"Attempting to unlock Mini at {MINI_IP}...")

    result = subprocess.run(
        ["ssh", "-o", "ConnectTimeout=10", f"{MINI_USER}@{MINI_IP}", "echo 'System unlocked'"],
        check=False,
    )

    if result.returncode != 0:
        print("Failed to connect to Mini. Is it powered on?")
        return 1

    print("Mini should now be unlocked.")

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


if __name__ == "__main__":
    sys.exit(main())
