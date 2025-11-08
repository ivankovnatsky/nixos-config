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

# Handle log file redirection
if [[ "${BACKUP_LOG_REDIRECTED:-}" != "1" ]]; then
  # Check if --no-log-file is present
  DISABLE_LOGGING=false
  for arg in "$@"; do
    if [[ "$arg" == "--no-log-file" ]]; then
      DISABLE_LOGGING=true
      break
    fi
  done

  # Enable logging by default
  if [[ "$DISABLE_LOGGING" == "false" ]]; then
    LOG_FILE="/tmp/backup-home-simple-$(date +%Y%m%d-%H%M%S).log"
    echo "Logging to: $LOG_FILE"
    export BACKUP_LOG_REDIRECTED=1
    exec "$0" "$@" &> "$LOG_FILE"
  fi
fi

# Parse command line arguments
SKIP_BACKUP=false
SKIP_UPLOAD=false
CUSTOM_ARCHIVE_PATH=""

while [[ $# -gt 0 ]]; do
  case $1 in
  --skip-backup)
    SKIP_BACKUP=true
    shift
    ;;
  --skip-upload)
    SKIP_UPLOAD=true
    shift
    ;;
  --backup-path)
    CUSTOM_ARCHIVE_PATH="$2"
    shift 2
    ;;
  --no-log-file)
    # Already handled at the top of the script, just skip
    shift
    ;;
  *)
    echo "Unknown option: $1"
    echo "Usage: $0 [--skip-backup] [--skip-upload] [--backup-path <path>] [--no-log-file]"
    exit 1
    ;;
  esac
done

# Set archive path
if [[ -n "$CUSTOM_ARCHIVE_PATH" ]]; then
  ARCHIVE_PATH="$CUSTOM_ARCHIVE_PATH"
elif [[ -d "/Volumes/Storage/Data" ]] && [[ -w "/Volumes/Storage/Data" ]]; then
  TEMP_DIR="/Volumes/Storage/Data/Tmp"
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
    --exclude='**/.cache/uv/archive-v0/**' \
    --exclude='**/.cargo/registry/**' \
    --exclude='**/.codeium/**' \
    --exclude='**/.cursor/extensions/**' \
    --exclude='**/.gnupg/S.*' \
    --exclude='**/.npm/**' \
    --exclude='**/.ollama/**' \
    --exclude='**/.terraform.d/**' \
    --exclude='**/.Trash/**' \
    --exclude='**/.vscode/**' \
    --exclude='**/.vscode-oss/**' \
    --exclude='**/*.sock' \
    --exclude='**/*.socket' \
    --exclude='**/go/**' \
    --exclude='**/Group Containers/HUAQ24HBR6.dev.orbstack/**' \
    --exclude='**/Library/Application Support/Firefox/**' \
    --exclude='**/Library/Application Support/Chromium/**' \
    --exclude='**/Library/Application Support/Google/Chrome/**' \
    --exclude='**/Library/Application Support/Vivaldi/**' \
    --exclude='**/Library/Application Support/Cursor/**' \
    --exclude='**/Library/Application Support/Code/**' \
    --exclude='**/Library/Application Support/Windsurf/**' \
    --exclude='**/Library/Application Support/virtualenv/**' \
    --exclude='**/Library/Application Support/Slack/**' \
    --exclude='**/Library/Application Support/rancher-desktop/**' \
    --exclude='**/Library/Caches/Google/Chrome/**' \
    --exclude='**/Library/Caches/Firefox/Profiles/**' \
    --exclude='**/Library/Caches/go-build/**' \
    --exclude='**/Library/Caches/pypoetry/**' \
    --exclude='**/Library/Caches/typescript/**' \
    --exclude='**/Library/Caches/Chromium/**' \
    --exclude='**/Library/Mobile Documents/**' \
    --exclude='**/Library/Metadata/**' \
    --exclude='**/Library/pnpm/**' \
    --exclude='**/Library/Containers/com.apple.AvatarUI.AvatarPickerMemojiPicker/**' \
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
    "$USER" |
    pigz >"$ARCHIVE_PATH"
fi

if [[ "$SKIP_UPLOAD" == "true" ]]; then
  echo "Skipping upload to mini, backup saved at: $ARCHIVE_PATH"
else
  export TARGET_MACHINE=192.168.50.4
  export BACKUP_PATH=/Volumes/Storage/Data/Drive/Crypt/Machines/
  HOSTNAME=$(hostname)
  export HOSTNAME
  DATE_DIR=$(date +%Y-%m-%d)
  export DATE_DIR

  # Extract the parent directory name from $HOME (e.g., "Users" on macOS, "home" on Linux)
  # This handles both /Users/ivan and /home/ivan cases
  HOME_PARENT_DIR=$(basename "$(dirname "$HOME")")
  export HOME_PARENT_DIR

  if [[ ${TARGET_MACHINE,,} == ${HOSTNAME,,}.local ]]; then
    mkdir -p "$BACKUP_PATH/$HOSTNAME/$HOME_PARENT_DIR/$DATE_DIR"
    mv "$ARCHIVE_PATH" "$BACKUP_PATH/$HOSTNAME/$HOME_PARENT_DIR/$DATE_DIR/$USER.tar.gz"
  else
    # shellcheck disable=SC2029
    ssh "ivan@$TARGET_MACHINE" "mkdir -p $BACKUP_PATH/$HOSTNAME/$HOME_PARENT_DIR/$DATE_DIR"
    scp "$ARCHIVE_PATH" ivan@"$TARGET_MACHINE:$BACKUP_PATH/$HOSTNAME/$HOME_PARENT_DIR/$DATE_DIR/$USER.tar.gz"
    rm "$ARCHIVE_PATH"
  fi
fi
