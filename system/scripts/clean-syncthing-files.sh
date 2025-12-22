#!/usr/bin/env bash

set -euo pipefail

DELETE=false
MAX_FILES=50

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delete) DELETE=true; shift ;;
    *) break ;;
  esac
done

dirs=("${@:-.}")
pattern='\.sync-conflict-|^\.syncthing\..*\.tmp$'

for dir in "${dirs[@]}"; do
  if [ ! -d "$dir" ]; then
    echo "Skipping (not found): $dir"
    continue
  fi

  files=$(fd --hidden --no-ignore --type f "$pattern" "$dir")
  count=$(echo "$files" | grep -c . || true)

  echo "Found $count files in: $dir"

  if [ "$count" -eq 0 ]; then
    continue
  fi

  if [ "$count" -gt "$MAX_FILES" ]; then
    echo "ERROR: Too many files ($count > $MAX_FILES). Aborting."
    exit 1
  fi

  echo "$files"

  if [ "$DELETE" = true ]; then
    echo "$files" | xargs rm -v
  else
    echo "Dry-run mode. Use --delete to remove files."
  fi
done

echo "Syncthing cleanup complete at $(date)"
