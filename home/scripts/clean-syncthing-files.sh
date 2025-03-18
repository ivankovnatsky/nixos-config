#!/usr/bin/env bash
# clean-syncthing-files.sh - Script to clean up Syncthing conflict files
# Usage: ./clean-syncthing-files.sh [--dry-run] [--verbose] [path]

set -e

# Default settings
DRY_RUN=0
VERBOSE=0
SEARCH_PATH="."

# Process command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    -h|--help)
      echo "Usage: $(basename $0) [--dry-run] [--verbose] [path]"
      echo ""
      echo "Options:"
      echo "  --dry-run    Show what would be deleted without actually deleting"
      echo "  --verbose    Show all files that would be deleted"
      echo "  --help       Show this help message"
      echo "  [path]       Directory to search (default: current directory)"
      exit 0
      ;;
    *)
      SEARCH_PATH="$1"
      shift
      ;;
  esac
done

# Print header
echo "Syncthing Conflict Files Cleanup"
echo "================================"
if [ $DRY_RUN -eq 1 ]; then
  echo "DRY RUN MODE: No files will be deleted"
fi
echo "Searching in: $SEARCH_PATH"
echo ""

# Function to find and optionally delete files
find_and_clean() {
  local pattern="$1"
  local description="$2"
  
  echo "Looking for $description..."
  
  # Find the files - using macOS compatible syntax
  local files=$(find "$SEARCH_PATH" -type f -name "$pattern" 2>/dev/null)
  local count=0
  
  if [ -n "$files" ]; then
    count=$(echo "$files" | grep -c "")
  fi
  
  if [ -z "$files" ] || [ "$count" -eq 0 ]; then
    echo "No $description found."
    echo ""
    return 0
  fi
  
  echo "Found $count $description:"
  
  if [ $VERBOSE -eq 1 ] || [ $DRY_RUN -eq 1 ]; then
    echo "$files" | sed 's/^/  /'
  else
    echo "$files" | head -n 5 | sed 's/^/  /'
    if [ $count -gt 5 ]; then
      echo "  ... and $((count - 5)) more files"
    fi
  fi
  
  # Delete the files if not in dry-run mode
  if [ $DRY_RUN -eq 0 ]; then
    echo "Deleting $count files..."
    echo "$files" | while read file; do
      rm -f "$file"
    done
    echo "Deleted $count $description."
  else
    echo "Would delete $count $description."
  fi
  
  echo ""
  return $count
}

# Find and clean different types of Syncthing conflict files
total=0

# Temporary files
count=0
find_and_clean "*syncthing*tmp" "temporary Syncthing files"
total=$((total + $?))

# Sync conflict files
count=0
find_and_clean "*sync-conflict*" "Syncthing conflict files"
total=$((total + $?))

# Old version files
count=0
find_and_clean "*.syncthing.*.tmp" "Syncthing old version files"
total=$((total + $?))

# Summary
echo "Summary:"
echo "========"
if [ $DRY_RUN -eq 1 ]; then
  echo "Would have deleted $total Syncthing-related files."
  echo "Run without --dry-run to actually delete the files."
else
  echo "Deleted $total Syncthing-related files."
fi

exit 0
