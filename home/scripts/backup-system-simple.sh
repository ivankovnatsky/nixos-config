#!/usr/bin/env bash

# Root filesystem backup script for Unix systems.
# Purpose: Backup system files excluding user homes and temporary data.

# https://stackoverflow.com/a/984259

set -euo pipefail

# Check if running as root, if not re-exec with sudo
if [[ $EUID -ne 0 ]]; then
  exec sudo bash "$0" "$@"
fi

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
HOSTNAME=$(hostname)

if [[ -n "$CUSTOM_ARCHIVE_PATH" ]]; then
  ARCHIVE_PATH="$CUSTOM_ARCHIVE_PATH"
elif [[ ${HOSTNAME,,} == "bee" ]]; then
  TEMP_DIR="/storage/Data/tmp"
  mkdir -p "$TEMP_DIR"
  ARCHIVE_PATH="$TEMP_DIR/system.tar.gz"
elif [[ -d "/Volumes/Storage/Data" ]] && [[ -w "/Volumes/Storage/Data" ]]; then
  TEMP_DIR="/Volumes/Storage/Data/tmp"
  mkdir -p "$TEMP_DIR"
  ARCHIVE_PATH="$TEMP_DIR/system.tar.gz"
else
  TEMP_DIR="/tmp"
  ARCHIVE_PATH="/tmp/system.tar.gz"
fi

# Skip backup creation if requested
if [[ "$SKIP_BACKUP" == "true" ]]; then
  if [[ ! -f "$ARCHIVE_PATH" ]]; then
    echo "Error: --skip-backup specified but no backup file exists at $ARCHIVE_PATH"
    exit 1
  fi
  echo "Skipping backup creation, using existing file: $ARCHIVE_PATH"
else
  cd / || exit 1

  tar \
    --exclude='home/**' \
    --exclude='nix/**' \
    --exclude='storage/**' \
    --exclude='tmp/**' \
    --exclude='var/tmp/**' \
    --exclude='var/lib/docker/overlay2/**' \
    --exclude='proc/**' \
    --exclude='sys/**' \
    --exclude='dev/**' \
    --exclude='run/**' \
    --exclude='mnt/**' \
    --exclude='media/**' \
    \
    --no-xattrs \
    \
    -cv \
    . |
    pigz >"$ARCHIVE_PATH"
fi

export TARGET_MACHINE=192.168.50.4
DATE_DIR=$(date +%Y-%m-%d)
export DATE_DIR

# Determine backup path based on hostname
if [[ ${HOSTNAME,,} == "bee" ]]; then
  BACKUP_PATH=/storage/Data/Drive/Crypt/Machines/
  mkdir -p "$BACKUP_PATH/$HOSTNAME/system/$DATE_DIR"
  chown -R ivan:users "$BACKUP_PATH/$HOSTNAME"
  mv "$ARCHIVE_PATH" "$BACKUP_PATH/$HOSTNAME/system/$DATE_DIR/system.tar.gz"
  chmod 644 "$BACKUP_PATH/$HOSTNAME/system/$DATE_DIR/system.tar.gz"
  chown ivan:users "$BACKUP_PATH/$HOSTNAME/system/$DATE_DIR/system.tar.gz"
else
  BACKUP_PATH=/Volumes/Storage/Data/Drive/Crypt/Machines/
  # shellcheck disable=SC2029
  ssh "ivan@$TARGET_MACHINE" "mkdir -p $BACKUP_PATH/$HOSTNAME/system/$DATE_DIR"
  scp "$ARCHIVE_PATH" ivan@"$TARGET_MACHINE:$BACKUP_PATH/$HOSTNAME/system/$DATE_DIR/system.tar.gz"
  rm "$ARCHIVE_PATH"
fi
