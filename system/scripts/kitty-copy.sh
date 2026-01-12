#!/usr/bin/env bash

set -euo pipefail

# Check dependencies
for cmd in kitty jq fzf; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is required but not installed." >&2
    exit 1
  fi
done

# Detect clipboard command
if [[ "$OSTYPE" == "darwin"* ]]; then
  CLIPBOARD_CMD="pbcopy"
elif command -v wl-copy &>/dev/null; then
  CLIPBOARD_CMD="wl-copy"
elif command -v xclip &>/dev/null; then
  CLIPBOARD_CMD="xclip -selection clipboard"
else
  echo "Error: No clipboard tool found (pbcopy, wl-copy, or xclip)" >&2
  exit 1
fi

# Function to get text from a window ID
copy_from_id() {
  local id="$1"
  # Try to capture stderr to check for kitty socket errors
  if ! kitty @ get-text --match "id:$id" --extent=all | $CLIPBOARD_CMD; then
    echo "Error: Failed to get text from kitty window $id." >&2
    echo "Make sure you are running this from within kitty or have remote control enabled." >&2
    exit 1
  fi
  echo "Copied content from window $id to clipboard."
}

# If argument provided, use it as ID
if [[ $# -ge 1 ]]; then
  copy_from_id "$1"
  exit 0
fi

# Interactive mode
# List all kitty windows (panes) with their IDs, titles, and foreground processes
selection=$(kitty @ ls |
  jq -r '.[] | .tabs[] | .windows[] | "\(.id): \(.title) [\(.foreground_processes[0].cmdline[0] // "unknown")]"' |
  fzf --prompt="Select kitty window> " --height=40% --layout=reverse --border)

if [[ -n "$selection" ]]; then
  # Extract ID (everything before the first colon)
  id=$(echo "$selection" | cut -d':' -f1)
  copy_from_id "$id"
fi