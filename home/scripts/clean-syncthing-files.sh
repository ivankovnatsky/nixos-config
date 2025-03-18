#!/usr/bin/env bash

# Script to clean up Syncthing conflict files and temporary files
# Uses fd to find and delete files in one step

# Default to normal run mode
DRY_RUN=0

# Process command line arguments
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

# Set the directory to clean (default to current directory if not specified)
DIR="${1:-.}"

echo "Cleaning Syncthing conflict files and temporary files in: $DIR"
if [[ $DRY_RUN -eq 1 ]]; then
  echo "DRY RUN MODE: No files will be deleted"
fi

# Define the base fd command to avoid duplication
FD_BASE_CMD="fd --hidden --exclude '.git' '(\.sync-conflict|\.syncthing.*\.tmp|syncthing.*tmp)' \"$DIR\""

# Use fd to find and delete all Syncthing-related files in one command
# This includes:
# - .sync-conflict-* files (conflict files)
# - *.syncthing.*.tmp files (temporary files)
# - *syncthing*tmp files (other temporary files)
if [[ $DRY_RUN -eq 1 ]]; then
  # In dry-run mode, just list the files
  echo "Files that would be deleted:"
  eval "$FD_BASE_CMD --exec echo '  {}'"
else
  # Normal mode - delete the files
  eval "$FD_BASE_CMD --exec rm --verbose {}"
fi

echo "Cleanup complete!"
