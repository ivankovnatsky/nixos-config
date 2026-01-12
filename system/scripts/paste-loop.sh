#!/usr/bin/env bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

filename="$1"

# Detect clipboard command
if command -v pbpaste &>/dev/null; then
  PASTE_CMD="pbpaste"
elif command -v wl-paste &>/dev/null; then
  PASTE_CMD="wl-paste"
else
  echo "Error: No clipboard tool found (pbpaste or wl-paste)" >&2
  exit 1
fi

# Create file if it doesn't exist
touch "$filename"

# Function for paste loop
paste_loop() {
  while true; do
    sleep 1
    paste_content="$($PASTE_CMD)"
    if ! grep -Fxq "$paste_content" "$filename" 2>/dev/null; then
      echo "$paste_content" >>"$filename"
    fi
  done
}

# Start paste loop in background
paste_loop &
paste_pid=$!

# Cleanup function to kill paste loop when script exits
cleanup() {
  kill $paste_pid 2>/dev/null
  exit
}

# Set up trap to cleanup on script exit
trap cleanup EXIT INT TERM

# Run tail in foreground
tail -f "$filename"
