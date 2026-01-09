#!/usr/bin/env python3

"""
Primary backup script for Unix systems. Evolution journey:
1. Started with tar + rclone for cloud uploads
2. Explored standalone binaries for cross-platform support (Go, Rust, Python)
   - Go: Native but couldn't match scp speeds (5-38MB/s vs 109MB/s native)
   - Rust: librclone bindings lacked Windows support
   - Python: Too slow for large backups
3. Simplified to tar + ssh/scp with mini machine as single upload source

This bash version remains the best solution for Unix due to native scp speeds.
The Go version (github.com/ivankovnatsky/backup-home-go) exists for exploration
and Windows support, where a PowerShell script is used instead.

The purpose of this script is to only exclude directories to which user does
not have access in macOS and which contain some data that is not needed, like
VMs and so.

https://stackoverflow.com/a/984259

2026-01-09: Ported to Python for improved maintainability. Functionality unchanged.
"""

import argparse
import os
import platform
import shutil
import socket
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def check_tar_on_darwin() -> None:
    """On Darwin, verify we're using native bsdtar, not GNU tar."""
    if platform.system() != "Darwin":
        return

    try:
        result = subprocess.run(
            ["tar", "--version"], capture_output=True, text=True, check=False
        )
        version_output = result.stdout + result.stderr
        if "GNU" in version_output:
            print(
                "Error: GNU tar detected on macOS. Please use native bsdtar.",
                file=sys.stderr,
            )
            sys.exit(1)
    except FileNotFoundError:
        print("Error: tar not found", file=sys.stderr)
        sys.exit(1)


# Default storage path
DEFAULT_STORAGE_PATH = "/Volumes/Storage/Data"
DEFAULT_TARGET_MACHINE = "192.168.50.4"

# Directories to exclude from backup
EXCLUDE_PATTERNS = [
    "**/.cache/huggingface/**",
    "**/.cache/nix/**",
    "**/.cache/uv/archive-v0/**",
    "**/.cargo/registry/**",
    "**/.codeium/**",
    "**/.cursor/extensions/**",
    "**/.gnupg/S.*",
    "**/.npm/**",
    "**/.ollama/**",
    "**/.terraform.d/**",
    "**/.Trash/**",
    "**/.vscode/**",
    "**/.vscode-oss/**",
    "**/*.sock",
    "**/*.socket",
    "**/go/**",
    "**/Group Containers/HUAQ24HBR6.dev.orbstack/**",
    "**/Library/Application Support/Firefox/**",
    "**/Library/Application Support/Chromium/**",
    "**/Library/Application Support/Google/Chrome/**",
    "**/Library/Application Support/Vivaldi/**",
    "**/Library/Application Support/Cursor/**",
    "**/Library/Application Support/Code/**",
    "**/Library/Application Support/Windsurf/**",
    "**/Library/Application Support/virtualenv/**",
    "**/Library/Application Support/Slack/**",
    "**/Library/Application Support/rancher-desktop/**",
    "**/Library/Caches/Google/Chrome/**",
    "**/Library/Caches/Firefox/Profiles/**",
    "**/Library/Caches/go-build/**",
    "**/Library/Caches/pypoetry/**",
    "**/Library/Caches/typescript/**",
    "**/Library/Caches/Chromium/**",
    "**/Library/Mobile Documents/**",
    "**/Library/Metadata/**",
    "**/Library/pnpm/**",
    "**/Library/Containers/com.apple.AccessibilitySettingsWidgetExtension/**",
    "**/Library/Containers/com.apple.AppStore/**",
    "**/Library/Containers/com.apple.AvatarUI.AvatarPickerMemojiPicker/**",
    "**/Library/Containers/com.apple.findmy.FindMyWidgetItems/**",
    "**/Library/Containers/com.apple.photoanalysisd/**",
    "**/Library/Containers/com.apple.Safari/**",
    "**/Library/Containers/com.apple.Safari.WebApp/**",
    "**/Library/Containers/com.apple.mail.SpotlightIndexExtension/**",
    "**/Library/Containers/com.apple.wallpaper.extension.video/**",
    "**/Library/Containers/com.microsoft.teams2/**",
    "**/Library/Containers/com.utmapp.UTM/**",
    "**/Library/Group Containers/BJ4HAAB9B3.ZoomClient3rd/**",
    "**/Library/Group Containers/UBF8T346G9.ms/**",
    "**/Library/Group Containers/group.com.apple.CoreSpeech/**",
    "**/Library/Group Containers/group.com.apple.secure-control-center-preferences/**",
    "**/OrbStack/**",
    "**/.local/share/Steam/steamapps/**",
]


def get_local_ips() -> list[str]:
    """Get list of local IP addresses."""
    ips = ["127.0.0.1", "::1"]
    try:
        result = subprocess.run(
            ["ifconfig"], capture_output=True, text=True, check=False
        )
        for line in result.stdout.split("\n"):
            if "inet " in line:
                parts = line.strip().split()
                if len(parts) >= 2:
                    ips.append(parts[1])
    except FileNotFoundError:
        pass
    return ips


def is_local_target(target: str) -> bool:
    """Check if target machine is the local machine."""
    hostname = socket.gethostname().lower()

    # Check hostname matches
    target_lower = target.lower()
    if target_lower == hostname or target_lower == f"{hostname}.local":
        return True

    # Check IP addresses
    return target in get_local_ips()


def create_backup(archive_path: Path, user: str) -> bool:
    """Create tar.gz backup of home directory."""
    home_parent = Path.home().parent

    # Build tar command with exclusions
    cmd = ["tar"]
    for pattern in EXCLUDE_PATTERNS:
        cmd.extend(["--exclude", pattern])
    cmd.extend(["--no-xattrs", "-cv", user])

    try:
        # Run tar and pipe to pigz (stderr=None lets tar -v output show on terminal)
        with open(archive_path, "wb") as archive_file:
            tar_proc = subprocess.Popen(
                cmd, cwd=home_parent, stdout=subprocess.PIPE, stderr=None
            )
            pigz_proc = subprocess.Popen(
                ["pigz"],
                stdin=tar_proc.stdout,
                stdout=archive_file,
                stderr=None,
            )

            # Allow tar to receive SIGPIPE if pigz exits
            if tar_proc.stdout:
                tar_proc.stdout.close()

            pigz_proc.wait()
            tar_proc.wait()

        if tar_proc.returncode != 0 or pigz_proc.returncode != 0:
            print(f"Backup creation failed", file=sys.stderr)
            return False

        return True
    except Exception as e:
        print(f"Error creating backup: {e}", file=sys.stderr)
        return False


def upload_rclone(archive_path: Path, remote: str, home_parent_dir: str) -> bool:
    """Upload backup using rclone."""
    date_dir = datetime.now().strftime("%Y-%m-%d")
    remote_path = f"{remote}/{home_parent_dir}/{date_dir}"

    print(f"Uploading to rclone remote: {remote_path}")

    result = subprocess.run(
        ["rclone", "copy", str(archive_path), remote_path, "--progress"], check=False
    )
    return result.returncode == 0


def upload_miniserve(
    archive_path: Path,
    url: str,
    hostname: str,
    home_parent_dir: str,
    user: str,
    password: str,
) -> bool:
    """Upload backup using curl to miniserve."""
    date_dir = datetime.now().strftime("%Y-%m-%d")
    upload_path = f"/Backup/Machines/{hostname}/{home_parent_dir}/{date_dir}"

    print(f"Creating directory: {upload_path}")

    # Create directories
    auth = f"{user}:{password}"
    for mkdir_path, mkdir_name in [
        ("/Backup/Machines", hostname),
        (f"/Backup/Machines/{hostname}", home_parent_dir),
        (f"/Backup/Machines/{hostname}/{home_parent_dir}", date_dir),
    ]:
        subprocess.run(
            [
                "curl",
                "-s",
                "-u",
                auth,
                "-F",
                f"mkdir={mkdir_name}",
                f"{url}/upload?path={mkdir_path}",
            ],
            check=False,
        )

    print(f"Uploading to miniserve: {url}{upload_path}")

    result = subprocess.run(
        [
            "curl",
            "-u",
            auth,
            "-F",
            f"path=@{archive_path}",
            "-o",
            "/dev/null",
            f"{url}/upload?path={upload_path}",
        ],
        check=False,
    )
    return result.returncode == 0


def upload_scp(
    archive_path: Path,
    target: str,
    hostname: str,
    home_parent_dir: str,
    storage_path: str,
    user: str,
) -> bool:
    """Upload backup using scp."""
    date_dir = datetime.now().strftime("%Y-%m-%d")
    backup_path = f"{storage_path}/Backup/Machines"
    remote_dir = f"{backup_path}/{hostname}/{home_parent_dir}/{date_dir}"
    remote_file = f"{remote_dir}/{user}.tar.gz"

    print(f"Uploading to: {target}:{remote_file}")

    # Create remote directory
    result = subprocess.run(
        ["ssh", f"ivan@{target}", f"mkdir -p {remote_dir}"], check=False
    )
    if result.returncode != 0:
        return False

    # Upload file
    result = subprocess.run(
        ["scp", str(archive_path), f"ivan@{target}:{remote_file}"], check=False
    )
    return result.returncode == 0


def move_local(
    archive_path: Path,
    hostname: str,
    home_parent_dir: str,
    storage_path: str,
    user: str,
) -> bool:
    """Move backup to local storage."""
    date_dir = datetime.now().strftime("%Y-%m-%d")
    backup_path = Path(storage_path) / "Backup" / "Machines"
    target_dir = backup_path / hostname / home_parent_dir / date_dir
    target_file = target_dir / f"{user}.tar.gz"

    print(f"Moving backup to: {target_file}")

    try:
        target_dir.mkdir(parents=True, exist_ok=True)
        shutil.move(str(archive_path), str(target_file))
        return True
    except Exception as e:
        print(f"Error moving backup: {e}", file=sys.stderr)
        return False


def main():
    check_tar_on_darwin()

    parser = argparse.ArgumentParser(
        description="Backup home directory with automatic exclusions and remote upload.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Environment variables:
  MINISERVE_USER    Username for miniserve authentication
  MINISERVE_PASS    Password for miniserve authentication

Examples:
  %(prog)s                                    # Normal backup and upload
  %(prog)s --skip-upload                      # Create backup locally only
  %(prog)s --target-machine 192.168.50.5      # Upload to different machine
  %(prog)s --rclone drive:Backup              # Upload to Google Drive
  %(prog)s --miniserve http://192.168.50.4:8080  # Upload via curl to miniserve
  %(prog)s --skip-backup --skip-upload        # Use existing backup, no upload
""",
    )

    parser.add_argument(
        "--skip-backup",
        action="store_true",
        help="Skip backup creation, use existing archive",
    )
    parser.add_argument(
        "--skip-upload",
        action="store_true",
        help="Skip upload to remote machine, keep backup local",
    )
    parser.add_argument(
        "--delete-backup",
        action="store_true",
        help="Delete local backup after successful upload",
    )
    parser.add_argument(
        "--backup-path",
        type=str,
        help="Custom path for backup archive",
    )
    parser.add_argument(
        "--target-machine",
        type=str,
        default=DEFAULT_TARGET_MACHINE,
        help=f"Target machine for scp upload (default: {DEFAULT_TARGET_MACHINE})",
    )
    parser.add_argument(
        "--rclone",
        type=str,
        metavar="REMOTE",
        help="Use rclone remote instead of scp (e.g., drive:Backup)",
    )
    parser.add_argument(
        "--miniserve",
        type=str,
        metavar="URL",
        help="Upload via curl to miniserve (e.g., http://192.168.50.4:8080)",
    )

    args = parser.parse_args()

    # Get environment info
    user = os.environ.get("USER", os.getlogin())
    hostname = socket.gethostname()
    home_parent_dir = Path.home().parent.name
    storage_path = os.environ.get("STORAGE_DATA_PATH", DEFAULT_STORAGE_PATH)

    # Determine archive path
    if args.backup_path:
        archive_path = Path(args.backup_path)
    elif Path(storage_path).is_dir() and os.access(storage_path, os.W_OK):
        temp_dir = Path(storage_path) / "Tmp"
        temp_dir.mkdir(parents=True, exist_ok=True)
        archive_path = temp_dir / f"{user}.tar.gz"
    else:
        archive_path = Path("/tmp") / f"{user}.tar.gz"

    # Create or skip backup
    if args.skip_backup:
        if not archive_path.exists():
            print(
                f"Error: --skip-backup specified but no backup file exists at {archive_path}",
                file=sys.stderr,
            )
            sys.exit(1)
        print(f"Skipping backup creation, using existing file: {archive_path}")
    else:
        if not create_backup(archive_path, user):
            sys.exit(1)

    # Upload or skip
    if args.skip_upload:
        print(f"Skipping upload, backup saved at: {archive_path}")
        sys.exit(0)

    success = False

    if args.rclone:
        success = upload_rclone(archive_path, args.rclone, home_parent_dir)
    elif args.miniserve:
        miniserve_user = os.environ.get("MINISERVE_USER")
        miniserve_pass = os.environ.get("MINISERVE_PASS")
        if not miniserve_user or not miniserve_pass:
            print(
                "Error: MINISERVE_USER and MINISERVE_PASS environment variables required",
                file=sys.stderr,
            )
            sys.exit(1)
        success = upload_miniserve(
            archive_path,
            args.miniserve,
            hostname,
            home_parent_dir,
            miniserve_user,
            miniserve_pass,
        )
    elif is_local_target(args.target_machine):
        print("Target is local machine, moving backup locally")
        success = move_local(
            archive_path, hostname, home_parent_dir, storage_path, user
        )
    else:
        success = upload_scp(
            archive_path,
            args.target_machine,
            hostname,
            home_parent_dir,
            storage_path,
            user,
        )

    if success:
        print("Upload successful")
        if args.delete_backup:
            archive_path.unlink()
            print("Local backup deleted")
        else:
            print(f"Backup kept at: {archive_path}")
    else:
        print(
            f"Upload failed, keeping local backup at: {archive_path}", file=sys.stderr
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
