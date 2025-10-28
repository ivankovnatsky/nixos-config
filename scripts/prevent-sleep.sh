#!/usr/bin/env bash

# prevent-sleep - Prevent system from sleeping on macOS and Linux systems

show_help() {
  cat <<EOF
Usage: prevent-sleep [OPTIONS]

Prevent system from sleeping on macOS and Linux systems.

Options:
    -h, --help              Show this help message
    -t, --timeout SECONDS   Set timeout in seconds (default: 43200 = 12 hours)

Environment variables:
    TIMEOUT     Alternative way to set timeout in seconds

Examples:
    prevent-sleep              # Run with default 12 hour timeout
    prevent-sleep -t 7200      # Run with 2 hour timeout
    TIMEOUT=7200 prevent-sleep # Same as above

On macOS, uses caffeinate with options:
    -d: Prevent the display from sleeping
    -i: Prevent the system from idle sleeping
    -m: Prevent the disk from idle sleeping
    -s: Prevent the system from sleeping (valid only when running on AC power)

On Linux, uses either systemd-inhibit or xset depending on availability
EOF
}

# Parse command line arguments
case "$1" in
-h | --help)
  show_help
  exit 0
  ;;
-t | --timeout)
  if [[ -n "$2" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
    TIMEOUT="$2"
  else
    echo "Error: --timeout requires a number" >&2
    exit 1
  fi
  ;;
"")
  # No arguments is fine
  ;;
*)
  echo "Unknown option: $1" >&2
  show_help
  exit 1
  ;;
esac

# Function to check the operating system
get_os() {
  case "$(uname -s)" in
  Darwin*) echo 'macos' ;;
  Linux*) echo 'linux' ;;
  *) echo 'unknown' ;;
  esac
}

# Default timeout: 12 hours in seconds
DEFAULT_TIMEOUT=43200

# Allow override via environment variable
TIMEOUT=${TIMEOUT:-$DEFAULT_TIMEOUT}

# Function to prevent sleep on macOS
prevent_sleep_macos() {
  echo "Preventing sleep on macOS using caffeinate for ${TIMEOUT} seconds..."
  # Create assertions to:
  # -d prevent the display from sleeping
  # -i prevent the system from idle sleeping
  # -m prevent the disk from idle sleeping
  # -s prevent the system from sleeping (valid only when running on AC power)
  # -t specify timeout in seconds
  /usr/bin/caffeinate -d -i -m -s -t "${TIMEOUT}"
}

# Function to prevent sleep on Linux
prevent_sleep_linux() {
  if command -v systemd-inhibit &>/dev/null; then
    echo "Preventing sleep on Linux using systemd-inhibit for ${TIMEOUT} seconds..."
    # Inhibit multiple lock types to match macOS caffeinate behavior:
    # - idle: prevents the system from going idle
    # - sleep: prevents system suspend/sleep
    # - handle-lid-switch: prevents lid close from triggering sleep
    sudo systemd-inhibit --what=idle:sleep:handle-lid-switch --who="prevent-sleep" --why="User requested to prevent sleep" --mode=block sleep "${TIMEOUT}"
  elif command -v xset &>/dev/null; then
    echo "Preventing sleep on Linux using xset..."
    while true; do
      xset s off -dpms
      sleep 60
    done
  else
    echo "Error: Could not find suitable command to prevent sleep on Linux"
    exit 1
  fi
}

# Main script
os=$(get_os)

echo "Detected OS: $os"

case "$os" in
'macos')
  prevent_sleep_macos
  ;;
'linux')
  prevent_sleep_linux
  ;;
*)
  echo "Error: Unsupported operating system"
  exit 1
  ;;
esac
