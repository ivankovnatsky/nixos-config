#!/usr/bin/env bash

# The purpose of this script is to only exclude directories to which user does
# not have access in macOS and which contain some data that is not needed, like
# VMs and so.

# https://stackoverflow.com/a/984259

set -euo pipefail

# Check if /Volumes/Storage/Data is available and use it for temporary storage if it is
if [[ -d "/Volumes/Storage/Data" ]] && [[ -w "/Volumes/Storage/Data" ]]; then
  TEMP_DIR="/Volumes/Storage/Data/tmp"
  mkdir -p "$TEMP_DIR"
  ARCHIVE_PATH="$TEMP_DIR/$USER.tar.gz"
else
  TEMP_DIR="/tmp"
  ARCHIVE_PATH="/tmp/$USER.tar.gz"
fi

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

export TARGET_MACHINE=192.168.50.4
export BACKUP_PATH=/Volumes/Storage/Data/Drive/Crypt/Machines/
export HOSTNAME=$(hostname)
export DATE_DIR=$(date +%Y-%m-%d)

if [[ ${TARGET_MACHINE,,} == ${HOSTNAME,,}.local ]]; then
  mkdir -p "$BACKUP_PATH/$HOSTNAME/Users/$DATE_DIR"
  mv "$ARCHIVE_PATH" "$BACKUP_PATH/$HOSTNAME/Users/$DATE_DIR/$USER.tar.gz"
else
  ssh ivan@$TARGET_MACHINE "mkdir -p $BACKUP_PATH/$HOSTNAME/Users/$DATE_DIR"
  scp "$ARCHIVE_PATH" ivan@"$TARGET_MACHINE:$BACKUP_PATH/$HOSTNAME/Users/$DATE_DIR/$USER.tar.gz"
  rm "$ARCHIVE_PATH"
fi
