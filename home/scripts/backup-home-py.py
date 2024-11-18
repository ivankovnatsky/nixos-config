#!/usr/bin/env python3

import os
import sys
import subprocess
from pathlib import Path

# Global variables
CURRENT_USER = os.getenv("USER")
BACKUP_FILE = f"/tmp/{CURRENT_USER}.tar.gz"

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
    try:
        home = Path.home()
        os.chdir(home.parent)
        print(f"Creating backup of home directory for {CURRENT_USER}...")

        subprocess.run(["sudo", "-v"], check=True)

        tar_cmd = ["sudo", "tar", "-cf", "-"]
        for exclude in DARWIN_EXCLUDES:
            tar_cmd.extend(["--exclude", exclude])
        tar_cmd.append(CURRENT_USER)

        with open(BACKUP_FILE, "wb") as f:
            tar_proc = subprocess.Popen(tar_cmd, stdout=subprocess.PIPE)
            pv_proc = subprocess.Popen(["pv"], stdin=tar_proc.stdout, stdout=subprocess.PIPE)
            pigz_proc = subprocess.Popen(["pigz"], stdin=pv_proc.stdout, stdout=f)
            pigz_proc.wait()
        return True

    except KeyboardInterrupt:
        print("\nBackup interrupted by user")
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
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
