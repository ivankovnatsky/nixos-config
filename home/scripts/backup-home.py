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
    "./.Trash",
    "./.cache/nix",
    "./.cursor/extensions",
    "./.npm/_cacache",
    "./.orbstack",
    "./.terraform.d",
    "./.vscode/extensions",
    "./Library/Application Support/Cursor",
    "./Library/Application Support/Google",
    "./Library/Application Support/Slack",
    "./Library/Application Support/rancher-desktop",
    "./Library/Caches",
    "./Library/Caches/CloudKit",
    "./Library/Caches/FamilyCircle",
    "./Library/Caches/Firefox",
    "./Library/Caches/com.anthropic.claudefordesktop.ShipIt",
    "./Library/Caches/com.apple.HomeKit",
    "./Library/Caches/com.apple.Safari",
    "./Library/Caches/com.apple.ap.adprivacyd",
    "./Library/Caches/com.apple.containermanagerd",
    "./Library/Caches/com.apple.homed",
    "./Library/Caches/pypoetry",
    "./Library/Containers",
    "./Library/Group Containers",
    "./OrbStack",
    "./Sources/github.com/NixOS/nixpkgs",
]


def log(message: str) -> None:
    """Print a message with a timestamp prefix."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")


def backup_home():
    try:
        home = Path.home()
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
