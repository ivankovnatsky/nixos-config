#!/usr/bin/env python3

import os
import sys
import subprocess
import shutil
from pathlib import Path

# Global variables
CURRENT_USER = os.getenv("USER")
BACKUP_FILE = f"/tmp/{CURRENT_USER}.tar.gz"
MIN_BACKUP_SIZE_GB = 5
MAX_BACKUP_SIZE_GB = 20
MIN_BACKUP_SIZE_BYTES = MIN_BACKUP_SIZE_GB * 1024 * 1024 * 1024
MAX_BACKUP_SIZE_BYTES = MAX_BACKUP_SIZE_GB * 1024 * 1024 * 1024

# Platform-specific excludes
DARWIN_EXCLUDES = [
    f"./{CURRENT_USER}/.orbstack",
    f"./{CURRENT_USER}/.Trash",
    f"./{CURRENT_USER}/.cache/nix",
    f"./{CURRENT_USER}/.terraform.d",
    f"./{CURRENT_USER}/Library/Application Support/rancher-desktop",
    f"./{CURRENT_USER}/Library/Application Support/Google",
    f"./{CURRENT_USER}/Library/Application Support/Slack",
    f"./{CURRENT_USER}/Library/Caches",
    f"./{CURRENT_USER}/Library/Caches/com.apple.ap.adprivacyd",
    f"./{CURRENT_USER}/Library/Caches/com.apple.homed",
    f"./{CURRENT_USER}/Library/Caches/FamilyCircle",
    f"./{CURRENT_USER}/Library/Caches/com.apple.containermanagerd",
    f"./{CURRENT_USER}/Library/Caches/com.apple.Safari",
    f"./{CURRENT_USER}/Library/Caches/CloudKit",
    f"./{CURRENT_USER}/Library/Caches/com.apple.HomeKit",
    f"./{CURRENT_USER}/Library/Group Containers",
    f"./{CURRENT_USER}/OrbStack",
    "./**/*.sock",
    "./.gnupg/S.*",
]


def backup_home():
    home = Path.home()
    os.chdir(home.parent)
    print(f"Creating backup of home directory for {CURRENT_USER}...")

    subprocess.run(["sudo", "-v"], check=True)

    # Get estimated size with error handling
    try:
        du_proc = subprocess.run(
            ["sudo", "du", "-sb", CURRENT_USER],
            capture_output=True,
            text=True,
            check=True,
        )
        total_size = int(du_proc.stdout.split()[0])
    except (subprocess.CalledProcessError, ValueError, IndexError) as e:
        print(f"Warning: Could not get directory size: {e}")
        # Use a reasonable default size if we can't get the actual size
        total_size = 10 * 1024 * 1024 * 1024  # 10GB default

    tar_cmd = ["sudo", "tar", "-cf", "-"]
    for exclude in DARWIN_EXCLUDES:
        tar_cmd.extend(["--exclude", exclude])
    tar_cmd.append(CURRENT_USER)

    # Updated pv command with full progress info
    tar_proc = subprocess.Popen(tar_cmd, stdout=subprocess.PIPE)
    pv_proc = subprocess.Popen(
        ["pv", "-p", "-t", "-e", "-r", "-s", str(total_size)],
        stdin=tar_proc.stdout,
        stdout=subprocess.PIPE,
    )
    pigz_proc = subprocess.Popen(["pigz"], stdin=pv_proc.stdout, stdout=subprocess.PIPE)

    with open(BACKUP_FILE, "wb") as f:
        shutil.copyfileobj(pigz_proc.stdout, f)

    if os.path.exists(BACKUP_FILE):
        size = os.path.getsize(BACKUP_FILE)
        if MIN_BACKUP_SIZE_BYTES < size < MAX_BACKUP_SIZE_BYTES:
            print(
                f"Backup completed successfully: {BACKUP_FILE} (Size: {size/1024/1024/1024:.1f}GB)"
            )
            return True
        elif size <= MIN_BACKUP_SIZE_BYTES:
            print(f"Backup file too small (< {MIN_BACKUP_SIZE_GB} GB)")
        else:
            print(f"Backup file too large (> {MAX_BACKUP_SIZE_GB} GB)")
    else:
        print("Backup file was not created")
    return False


def upload_backup():
    print("Uploading backup to drive:...")
    subprocess.run(["rclone", "--progress", "copy", BACKUP_FILE, "drive:"], check=True)


def cleanup_backup():
    print(f"Cleaning up temporary backup file: {BACKUP_FILE}...")
    os.remove(BACKUP_FILE)


def main():
    try:
        if backup_home():
            upload_backup()
            cleanup_backup()
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
