#!/usr/bin/env bash

# Primary backup script for Unix systems. Evolution journey:
# 1. Started with tar + rclone for cloud uploads
# 2. Explored standalone binaries for cross-platform support (Go, Rust, Python)
#    - Go: Native but couldn't match scp speeds (5-38MB/s vs 109MB/s native)
#    - Rust: librclone bindings lacked Windows support
#    - Python: Too slow for large backups
# 3. Simplified to tar + ssh/scp with mini machine as single upload source
# 
# This bash version remains the best solution for Unix due to native scp speeds.
# The Go version (github.com/ivankovnatsky/backup-home-go) exists for exploration
# and Windows support, where a PowerShell script is used instead.
#
# The purpose of this script is to only exclude directories to which user does
# not have access in macOS and which contain some data that is not needed, like
# VMs and so.

# https://stackoverflow.com/a/984259

set -euo pipefail

# Parse command line arguments
SKIP_BACKUP=false
CUSTOM_ARCHIVE_PATH=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-backup)
      SKIP_BACKUP=true
      shift
      ;;
    --backup-path)
      CUSTOM_ARCHIVE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--skip-backup] [--backup-path <path>]"
      exit 1
      ;;
  esac
done

# Set archive path
if [[ -n "$CUSTOM_ARCHIVE_PATH" ]]; then
  ARCHIVE_PATH="$CUSTOM_ARCHIVE_PATH"
elif [[ -d "/Volumes/Storage/Data" ]] && [[ -w "/Volumes/Storage/Data" ]]; then
  TEMP_DIR="/Volumes/Storage/Data/tmp"
  mkdir -p "$TEMP_DIR"
  ARCHIVE_PATH="$TEMP_DIR/$USER.tar.gz"
else
  TEMP_DIR="/tmp"
  ARCHIVE_PATH="/tmp/$USER.tar.gz"
fi

# Skip backup creation if requested
if [[ "$SKIP_BACKUP" == "true" ]]; then
  if [[ ! -f "$ARCHIVE_PATH" ]]; then
    echo "Error: --skip-backup specified but no backup file exists at $ARCHIVE_PATH"
    exit 1
  fi
  echo "Skipping backup creation, using existing file: $ARCHIVE_PATH"
else
  cd "$HOME/../" || exit 1

tar \
    --exclude='**/.cache/huggingface/**' \
    --exclude='**/.cache/nix/**' \
    --exclude='**/.cargo/registry/**' \
    --exclude='**/.codeium/**' \
    --exclude='**/.cursor/extensions/**' \
    --exclude='**/.gnupg/S.*' \
    --exclude='**/.npm/**' \
    --exclude='**/.ollama/**' \
    --exclude='**/.terraform.d/**' \
    --exclude='**/.Trash/**' \
    --exclude='**/.vscode/**' \
    --exclude='**/*.sock' \
    --exclude='**/*.socket' \
    --exclude='**/go/**' \
    --exclude='**/Group Containers/HUAQ24HBR6.dev.orbstack/**' \
    --exclude='**/Library/Application Support/Firefox/**' \
    --exclude='**/Library/Application Support/Chromium/**' \
    --exclude='**/Library/Application Support/Google/Chrome/**' \
    --exclude='**/Library/Application Support/Cursor/**' \
    --exclude='**/Library/Application Support/Code/**' \
    --exclude='**/Library/Application Support/Windsurf/**' \
    --exclude='**/Library/Application Support/virtualenv/**' \
    --exclude='**/Library/Application Support/Slack/**' \
    --exclude='**/Library/Caches/Google/Chrome/**' \
    --exclude='**/Library/Caches/Firefox/Profiles/**' \
    --exclude='**/Library/Caches/go-build/**' \
    --exclude='**/Library/Caches/pypoetry/**' \
    --exclude='**/Library/Caches/typescript/**' \
    --exclude='**/Library/Caches/Chromium/**' \
    --exclude='**/Library/Mobile Documents/**' \
    --exclude='**/Library/pnpm/**' \
    --exclude='**/Library/Containers/com.apple.Safari/**' \
    --exclude='**/Library/Containers/com.apple.Safari.WebApp/**' \
    --exclude='**/Library/Containers/com.apple.wallpaper.extension.video/**' \
    --exclude='**/Library/Containers/com.microsoft.teams2/**' \
    --exclude='**/Library/Containers/com.utmapp.UTM/**' \
    --exclude='**/Library/Group Containers/BJ4HAAB9B3.ZoomClient3rd/**' \
    --exclude='**/Library/Group Containers/group.com.apple.CoreSpeech/**' \
    --exclude='**/Library/Group Containers/group.com.apple.secure-control-center-preferences/**' \
    --exclude='**/OrbStack/**' \
    --exclude='**/.local/share/Steam/steamapps/**' \
    \
    --no-xattrs \
    \
    -cv \
    "$USER" | \
    \
    pigz > "$ARCHIVE_PATH"
fi

export TARGET_MACHINE=192.168.50.4
export BACKUP_PATH=/Volumes/Storage/Data/Drive/Crypt/Machines/
export HOSTNAME=$(hostname)
export DATE_DIR=$(date +%Y-%m-%d)

# Extract the parent directory name from $HOME (e.g., "Users" on macOS, "home" on Linux)
# This handles both /Users/ivan and /home/ivan cases
export HOME_PARENT_DIR=$(basename $(dirname "$HOME"))

if [[ ${TARGET_MACHINE,,} == ${HOSTNAME,,}.local ]]; then
  mkdir -p "$BACKUP_PATH/$HOSTNAME/$HOME_PARENT_DIR/$DATE_DIR"
  mv "$ARCHIVE_PATH" "$BACKUP_PATH/$HOSTNAME/$HOME_PARENT_DIR/$DATE_DIR/$USER.tar.gz"
else
  ssh ivan@$TARGET_MACHINE "mkdir -p $BACKUP_PATH/$HOSTNAME/$HOME_PARENT_DIR/$DATE_DIR"
  scp "$ARCHIVE_PATH" ivan@"$TARGET_MACHINE:$BACKUP_PATH/$HOSTNAME/$HOME_PARENT_DIR/$DATE_DIR/$USER.tar.gz"
  rm "$ARCHIVE_PATH"
fi
