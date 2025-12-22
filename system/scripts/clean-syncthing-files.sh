#!/usr/bin/env bash

set -ex

# Clean Syncthing conflict files from specified directories (or current directory)
dirs=("${@:-.}")

for dir in "${dirs[@]}"; do
  if [ -d "$dir" ]; then
    echo "Cleaning Syncthing files in: $dir"
    fd --hidden --no-ignore --type f \
      '(sync-conflict|\.syncthing\..*\.tmp$)' "$dir" \
      --exec rm -v {}
  else
    echo "Skipping (not found): $dir"
  fi
done

echo "Syncthing cleanup complete at $(date)"
