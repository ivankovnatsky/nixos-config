#!/usr/bin/env bash

set -x

# Define a function for finding only Syncthing-related conflict files
find_syncthing_files() {
  find . -type f \( \
    -name "*sync-conflict*" -o \
    -name ".syncthing.*.tmp" \
  \) "$@"
}

# First show files that will be deleted
find_syncthing_files

# Then delete them
find_syncthing_files -delete

# Verify no files remain
find_syncthing_files
