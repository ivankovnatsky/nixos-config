#!/usr/bin/env bash

set -e  # Exit on first error

CURRENT_USER=$(whoami)
BACKUP_FILE="/tmp/${CURRENT_USER}.tar.gz"

# Platform-specific excludes
DARWIN_EXCLUDES=(
    --exclude="./${CURRENT_USER}/.orbstack"
    --exclude="./${CURRENT_USER}/.Trash"
    --exclude="./${CURRENT_USER}/.cache/nix"
    --exclude="./${CURRENT_USER}/.terraform.d"
    --exclude="./${CURRENT_USER}/Library/Application Support/rancher-desktop"
    --exclude="./${CURRENT_USER}/Library/Application Support/Google"
    --exclude="./${CURRENT_USER}/Library/Application Support/Slack"
    --exclude="./${CURRENT_USER}/Library/Caches"
    --exclude="./${CURRENT_USER}/Library/Caches/com.apple.ap.adprivacyd"
    --exclude="./${CURRENT_USER}/Library/Caches/com.apple.homed"
    --exclude="./${CURRENT_USER}/Library/Caches/FamilyCircle"
    --exclude="./${CURRENT_USER}/Library/Caches/com.apple.containermanagerd"
    --exclude="./${CURRENT_USER}/Library/Caches/com.apple.Safari"
    --exclude="./${CURRENT_USER}/Library/Caches/CloudKit"
    --exclude="./${CURRENT_USER}/Library/Caches/com.apple.HomeKit"
    --exclude="./${CURRENT_USER}/Library/Group Containers"
    --exclude="./${CURRENT_USER}/OrbStack"
    --exclude="./**/*.sock"
    --exclude="./.gnupg/S.*"
)

cd "$(dirname "$HOME")"
echo "Creating backup of home directory for ${CURRENT_USER}..."
sudo -v

sudo tar "${DARWIN_EXCLUDES[@]}" -cf - "${CURRENT_USER}/" | pv | pigz > "${BACKUP_FILE}"

echo "Uploading backup to drive:..."
rclone --progress copy "${BACKUP_FILE}" "drive:"

echo "Cleaning up temporary backup file: ${BACKUP_FILE}..."
rm "${BACKUP_FILE}" 
