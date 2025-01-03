#!/usr/bin/env python3

import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime
import argparse
import errno

# User configuration
CURRENT_USER = os.getenv("USER")

# Path configuration
BACKUP_FILE = f"/tmp/{CURRENT_USER}.tar.gz"

USER_PROFILE_DIR = f"/etc/profiles/per-user/{CURRENT_USER}/bin"
PIGZ_PATH = f"{USER_PROFILE_DIR}/pigz"
RCLONE_PATH = f"{USER_PROFILE_DIR}/rclone"

# Backup exclude patterns
DARWIN_EXCLUDES = [
    "./**/*.sock",
    "./.gnupg/S.*",
    f"./{CURRENT_USER}/.Trash",
    f"./{CURRENT_USER}/.cache/nix",
    f"./{CURRENT_USER}/.cursor/extensions",
    f"./{CURRENT_USER}/.npm/_cacache",
    f"./{CURRENT_USER}/.orbstack",
    f"./{CURRENT_USER}/.terraform.d",
    f"./{CURRENT_USER}/.vscode/extensions",
    f"./{CURRENT_USER}/Library/Application Support/Cursor",
    f"./{CURRENT_USER}/Library/Application Support/Google",
    f"./{CURRENT_USER}/Library/Application Support/Slack",
    f"./{CURRENT_USER}/Library/Application Support/rancher-desktop",
    f"./{CURRENT_USER}/Library/Caches",
    f"./{CURRENT_USER}/Library/Caches/CloudKit",
    f"./{CURRENT_USER}/Library/Caches/FamilyCircle",
    f"./{CURRENT_USER}/Library/Caches/Firefox",
    f"./{CURRENT_USER}/Library/Caches/com.anthropic.claudefordesktop.ShipIt",
    f"./{CURRENT_USER}/Library/Caches/com.apple.HomeKit",
    f"./{CURRENT_USER}/Library/Caches/com.apple.Safari",
    f"./{CURRENT_USER}/Library/Caches/com.apple.ap.adprivacyd",
    f"./{CURRENT_USER}/Library/Caches/com.apple.containermanagerd",
    f"./{CURRENT_USER}/Library/Caches/com.apple.homed",
    f"./{CURRENT_USER}/Library/Caches/pypoetry",
    f"./{CURRENT_USER}/Library/Containers",
    f"./{CURRENT_USER}/Library/Group Containers",
    f"./{CURRENT_USER}/OrbStack",
    f"./{CURRENT_USER}/Sources/github.com/NixOS/nixpkgs",
]


def log(message: str) -> None:
    """Print a message with a timestamp prefix."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")


def backup_home():
    try:
        home = Path.home()
        os.chdir(home.parent)
        log(f"Creating backup of home directory for {CURRENT_USER}...")

        tar_cmd = ["tar", "-cvf", "-"]
        for exclude in DARWIN_EXCLUDES:
            tar_cmd.extend(["--exclude", exclude])
        tar_cmd.append(CURRENT_USER)

        with open(BACKUP_FILE, "wb") as f:
            tar_proc = subprocess.Popen(tar_cmd, stdout=subprocess.PIPE)
            pigz_proc = subprocess.Popen([PIGZ_PATH], stdin=tar_proc.stdout, stdout=f)
            tar_proc.stdout.close()

            # Add timeout and better error handling
            ret_code = pigz_proc.wait(timeout=3600)  # 1 hour timeout
            if ret_code != 0:
                raise Exception(f"Compression failed with code {ret_code}")

            # Check tar process result too
            if tar_proc.wait() != 0:
                raise Exception("Tar process failed")

        return True

    except subprocess.TimeoutExpired:
        log("Backup process timed out")
        return False
    except OSError as e:
        if e.errno == errno.EINTR:  # Interrupted system call
            log("Backup was interrupted, retrying...")
            return backup_home()  # Recursive retry
        raise
    except KeyboardInterrupt:
        log("\nBackup interrupted by user")
        return False


def upload_backup(destination: str):
    log(f"Uploading backup to {destination}...")
    subprocess.run(
        [RCLONE_PATH, "--progress", "copy", BACKUP_FILE, destination], check=True
    )


def cleanup_backup():
    log(f"Cleaning up temporary backup file: {BACKUP_FILE}...")
    os.remove(BACKUP_FILE)


def main():
    examples = """
Examples:
    backup-home drive:
    backup-home gdrive:backup/home
    backup-home remote:path/to/backup/dir"""

    parser = argparse.ArgumentParser(
        description="Backup home directory and upload to rclone destination",
        epilog=examples,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "destination",
        help='Rclone destination path (e.g., "drive:", "gdrive:backup/home")',
    )

    # Show help if no arguments are provided
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)

    args = parser.parse_args()

    # Check if the destination includes a cloud name
    if ":" not in args.destination:
        log("Error: Destination must include a cloud name (e.g., 'drive:').")
        sys.exit(1)

    try:
        if backup_home():
            try:
                upload_backup(args.destination)
            finally:
                cleanup_backup()
    except Exception as e:
        log(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
