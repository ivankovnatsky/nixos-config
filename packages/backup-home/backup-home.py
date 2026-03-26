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

---

https://stackoverflow.com/a/984259

2026-01-09: Ported to Python for improved maintainability. Functionality unchanged.
2026-01-16: Removed scp support, miniserve is now the default upload method.
2026-01-16: Removed rclone support. Keep backup machine as single source of
            truth for sync with drive

---

Do not add file logging or redirect stderr. bsdtar on macOS writes both the -v
file listing and error messages (e.g. "Operation not permitted") to stderr.
Redirecting it to a log file hides errors from the caller and breaks failure
detection. Keep stderr going to the terminal for real-time visibility.
"""

import argparse
import os
import platform
import socket
import subprocess
import sys
from datetime import datetime
from pathlib import Path


SOPS_SECRETS = {
    "MINISERVE_USER": "miniserve-username",
    "MINISERVE_PASS": "miniserve-password",
}


def _read_secret(name: str) -> str | None:
    """Read secret from sops-nix file."""
    sops_name = SOPS_SECRETS.get(name)
    if sops_name:
        sops_path = Path.home() / ".config/sops-nix/secrets" / sops_name
        try:
            return sops_path.read_text().strip()
        except OSError:
            pass
    return None


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


# Defaults
DEFAULT_STORAGE_PATH = "/Volumes/Storage/Data"
DEFAULT_MINISERVE_URL = "http://192.168.50.4:8080"

EXCLUDE_PATTERNS: dict[str, list[str]] = {
    "runtime": [
        "**/.gnupg/S.*",
        "**/*.sock",
        "**/*.socket",
    ],
    "caches": [
        "**/.cache/huggingface/**",
        "**/.cache/nix/**",
        "**/.cache/uv/archive-v0/**",
        "**/Library/Caches/Google/Chrome/**",
        "**/Library/Caches/Firefox/Profiles/**",
        "**/Library/Caches/go-build/**",
        "**/Library/Caches/pypoetry/**",
        "**/Library/Caches/typescript/**",
        "**/Library/Caches/Chromium/**",
        "**/Library/Caches/Vivaldi/**",
        "**/Library/Caches/Comet/**",
    ],
    "dev_deps": [
        "**/.cargo/registry/**",
        "**/.npm/**",
        "**/.terraform.d/**",
        "**/go/**",
        "**/Library/Application Support/virtualenv/**",
        "**/Library/Biome/**",
        "**/Library/pnpm/**",
        "**/node_modules/**",
        "**/.terragrunt-cache/**",
    ],
    "large_blobs": [
        "**/.ollama/**",
        "**/.codeium/**",
        "**/OrbStack/**",
        "**/Group Containers/HUAQ24HBR6.dev.orbstack/**",
        "**/Library/Containers/com.utmapp.UTM/**",
        "**/.local/share/Steam/**",
        "**/.velocidrone/**",
        "**/Library/Application Support/Claude/vm_bundles/**",
        "**/Library/Application Support/rancher-desktop/**",
    ],
    "app_data": [
        "**/Library/Application Support/Firefox/**",
        "**/Library/Application Support/Chromium/**",
        "**/Library/Application Support/Google/Chrome/**",
        "**/Library/Application Support/Vivaldi/**",
        "**/Library/Application Support/Cursor/**",
        "**/Library/Application Support/Code/**",
        "**/Library/Application Support/Windsurf/**",
        "**/Library/Application Support/Slack/**",
        "**/.cursor/extensions/**",
        "**/.vscode/**",
        "**/.vscode-oss/**",
    ],
    "os_system": [
        "**/.Trash/**",
    ],
}

DEFAULT_EXCLUDE_CATEGORIES = [
    "runtime",
    "caches",
    "dev_deps",
    "large_blobs",
    "os_system",
]


def create_backup(
    archive_path: Path,
    user: str,
    ignore_tar_warnings: bool = False,
    no_excludes: bool = False,
    exclude_categories: list[str] | None = None,
) -> bool:
    """Create tar.gz backup of home directory."""
    home_parent = Path.home().parent

    # Build tar command with exclusions
    cmd = ["tar"]
    if not no_excludes:
        categories = (
            exclude_categories if exclude_categories else DEFAULT_EXCLUDE_CATEGORIES
        )
        for cat in categories:
            for pattern in EXCLUDE_PATTERNS[cat]:
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

        if pigz_proc.returncode != 0:
            print("Backup compression failed", file=sys.stderr)
            return False

        # bsdtar exit 1 = non-fatal warnings (permission denied, file changed)
        # GNU tar exit 2 = permission denied on some files
        if tar_proc.returncode != 0:
            if ignore_tar_warnings and tar_proc.returncode in (1, 2):
                print(
                    "Warning: tar completed with non-fatal errors (some files skipped)",
                    file=sys.stderr,
                )
            else:
                print("Backup creation failed", file=sys.stderr)
                return False

        return True
    except Exception as e:
        print(f"Error creating backup: {e}", file=sys.stderr)
        return False


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


def main():
    check_tar_on_darwin()

    parser = argparse.ArgumentParser(
        prog="backup-home",
        description="Backup home directory with automatic exclusions and remote upload.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Secrets (read from ~/.config/sops-nix/secrets/):
  miniserve-username    Username for miniserve authentication
  miniserve-password    Password for miniserve authentication

Examples:
  backup-home                              # Normal backup and upload via miniserve
  backup-home --skip-upload                # Create backup locally only
  backup-home --miniserve http://host:8080 # Upload via miniserve (custom URL)
  backup-home --skip-backup --skip-upload  # Use existing backup, no upload
""",
    )

    parser.add_argument(
        "--ignore-tar-warnings",
        action="store_true",
        help="Continue on non-fatal tar errors (e.g. permission denied)",
    )
    parser.add_argument(
        "--no-excludes",
        action="store_true",
        help="Disable all exclude patterns, backup everything",
    )
    category_names = ", ".join(EXCLUDE_PATTERNS.keys())
    parser.add_argument(
        "--exclude-categories",
        type=str,
        help=f"Comma-separated list of exclude categories to apply ({category_names})",
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
        "--miniserve",
        nargs="?",
        const=DEFAULT_MINISERVE_URL,
        metavar="URL",
        help=f"Custom miniserve URL (default: {DEFAULT_MINISERVE_URL})",
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
        exclude_cats = None
        if args.exclude_categories:
            exclude_cats = [c.strip() for c in args.exclude_categories.split(",")]
            invalid = [c for c in exclude_cats if c not in EXCLUDE_PATTERNS]
            if invalid:
                print(
                    f"Error: unknown exclude categories: {', '.join(invalid)}. "
                    f"Valid: {', '.join(EXCLUDE_PATTERNS.keys())}",
                    file=sys.stderr,
                )
                sys.exit(1)
        if not create_backup(
            archive_path, user, args.ignore_tar_warnings, args.no_excludes, exclude_cats
        ):
            sys.exit(1)

    # Upload or skip
    if args.skip_upload:
        print(f"Skipping upload, backup saved at: {archive_path}")
        sys.exit(0)

    miniserve_url = args.miniserve if args.miniserve else DEFAULT_MINISERVE_URL
    miniserve_user = _read_secret("MINISERVE_USER")
    miniserve_pass = _read_secret("MINISERVE_PASS")
    if not miniserve_user or not miniserve_pass:
        print(
            "Error: miniserve secrets not found in ~/.config/sops-nix/secrets/",
            file=sys.stderr,
        )
        sys.exit(1)
    success = upload_miniserve(
        archive_path,
        miniserve_url,
        hostname,
        home_parent_dir,
        miniserve_user,
        miniserve_pass,
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
