#!/usr/bin/env bash

set -euo pipefail

DELETE=false
MAX_FILES=10

usage() {
  cat <<EOF
Usage: clean-syncthing-files [OPTIONS] [DIRS...]

Clean Syncthing conflict and temp files from directories.

Options:
  --delete    Actually delete files (default is dry-run)
  --help      Show this help message

Arguments:
  DIRS        Directories to clean (default: current directory)

Safety:
  - Dry-run by default (shows files without deleting)
  - Aborts if more than $MAX_FILES files found (prevents bad pattern damage)
  - Matches: .sync-conflict-* and .syncthing.*.tmp files
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delete) DELETE=true; shift ;;
    --help|-h) usage ;;
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

  if [ "$count" -eq 0 ]; then
    echo "No Syncthing files found in: $dir"
    continue
  fi

  if [ "$count" -gt "$MAX_FILES" ]; then
    echo "ERROR: Too many files ($count > $MAX_FILES) in $dir. Aborting."
    exit 1
  fi

  echo "Found $count file(s) in: $dir"
  echo "$files"

  if [ "$DELETE" = true ]; then
    echo "Removing..."
    echo "$files" | xargs rm -v
  else
    echo "Dry-run mode. Use --delete to remove."
  fi
done

echo "Syncthing cleanup complete at $(date)"
