#!/usr/bin/env bash

# caffeinate - Prevent system from sleeping on macOS and Linux systems

show_help() {
    cat << EOF
Usage: caffeinate [OPTIONS]

Prevent system from sleeping on macOS and Linux systems.

Options:
    -h, --help              Show this help message
    -t, --timeout SECONDS   Set timeout in seconds (default: 3600 = 1 hour)

Environment variables:
    TIMEOUT     Alternative way to set timeout in seconds

Examples:
    caffeinate              # Run with default 1 hour timeout
    caffeinate -t 7200      # Run with 2 hour timeout
    TIMEOUT=7200 caffeinate # Same as above

On macOS, uses caffeinate with options:
    -i: Prevent the system from idle sleeping
    -m: Prevent the disk from idle sleeping

On Linux, uses either systemd-inhibit or xset depending on availability
EOF
}

# Parse command line arguments
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -t|--timeout)
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
    /usr/bin/caffeinate -i -m -t "${TIMEOUT}"
}

# Function to prevent sleep on Linux
prevent_sleep_linux() {
    if command -v systemctl &> /dev/null; then
        echo "Preventing sleep on Linux using systemd-inhibit for ${TIMEOUT} seconds..."
        systemd-inhibit --what=sleep:idle --who="caffeinate" --why="User requested to prevent sleep" --mode=block sleep "${TIMEOUT}"
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
