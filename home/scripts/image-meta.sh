#!/usr/bin/env bash

# image-meta.sh - Script to handle image metadata operations
# Usage: image-meta.sh [rm|ls] [file(s)]

set -e

function show_usage() {
  echo "Usage: image-meta.sh [command] [file(s)]"
  echo ""
  echo "Commands:"
  echo "  rm    - Remove all metadata from image file(s)"
  echo "  ls    - Display metadata for image file(s)"
  echo ""
  echo "Examples:"
  echo "  image-meta.sh rm photo.jpg"
  echo "  image-meta.sh ls *.png"
  exit 1
}

# Check if exiftool is installed
if ! command -v exiftool &>/dev/null; then
  echo "Error: exiftool is required but not installed."
  echo "Please install it first."
  exit 1
fi

# Check if command argument is provided
if [ $# -lt 1 ]; then
  show_usage
fi

command="$1"
shift

# Check if file arguments are provided
if [ $# -lt 1 ]; then
  echo "Error: No files specified."
  show_usage
fi

case "$command" in
"rm")
  echo "Removing metadata from: $@"
  exiftool -all= -overwrite_original "$@"
  echo "Metadata removed successfully."
  ;;
"ls")
  for file in "$@"; do
    echo "Metadata for: $file"
    echo "----------------------------------------"
    exiftool "$file"
    echo ""
  done
  ;;
*)
  echo "Error: Unknown command '$command'"
  show_usage
  ;;
esac
