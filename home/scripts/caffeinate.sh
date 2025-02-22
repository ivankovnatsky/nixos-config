#!/usr/bin/env bash

# dont-sleep.sh - Prevent system from sleeping on macOS and Linux systems
#
# Usage:
#   TIMEOUT=7200 ./dont-sleep.sh  # Set custom timeout in seconds (default: 1 hour)
#
# On macOS, this script uses caffeinate with the following options:
# -i: Prevent the system from idle sleeping
# -m: Prevent the disk from idle sleeping
# -t: Specify timeout in seconds (default: 3600 seconds = 1 hour)
#
# On Linux, it uses either systemd-inhibit or xset depending on availability

# Function to check the operating system
get_os() {
    case "$(uname -s)" in
        Darwin*)    echo 'macos';;
        Linux*)     echo 'linux';;
        *)         echo 'unknown';;
    esac
}

# Default timeout: 1 hour in seconds
DEFAULT_TIMEOUT=3600

# Allow override via environment variable
TIMEOUT=${TIMEOUT:-$DEFAULT_TIMEOUT}

# Function to prevent sleep on macOS
prevent_sleep_macos() {
    echo "Preventing sleep on macOS using caffeinate for ${TIMEOUT} seconds..."
    # Create assertions to:
    # -i prevent the system from idle sleeping
    # -m prevent the disk from idle sleeping
    # -t specify timeout in seconds
    caffeinate -t "${TIMEOUT}" -im
}

# Function to prevent sleep on Linux
prevent_sleep_linux() {
    if command -v systemctl &> /dev/null; then
        echo "Preventing sleep on Linux using systemd-inhibit for ${TIMEOUT} seconds..."
        systemd-inhibit --what=sleep:idle --who="dont-sleep.sh" --why="User requested to prevent sleep" --mode=block sleep "${TIMEOUT}"
    elif command -v xset &> /dev/null; then
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
