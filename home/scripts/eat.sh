#!/usr/bin/env bash

# Function to detect the operating system
get_os() {
    case "$(uname -s)" in
        Darwin*)    echo 'macos';;
        Linux*)     echo 'linux';;
        *)         echo 'unknown';;
    esac
}

# Function to check if required commands are available
check_dependencies() {
    local os=$1
    if [ "$os" = "linux" ]; then
        if ! command -v xclip >/dev/null 2>&1 && ! command -v xsel >/dev/null 2>&1 && ! command -v wl-copy >/dev/null 2>&1; then
            echo "Error: Please install either 'xclip', 'xsel', or 'wl-copy' for clipboard support"
            echo "X11 - Ubuntu/Debian: sudo apt-get install xclip"
            echo "X11 - Fedora: sudo dnf install xclip"
            echo "X11 - Arch: sudo pacman -S xclip"
            echo "Wayland - Ubuntu/Debian: sudo apt-get install wl-clipboard"
            echo "Wayland - Fedora: sudo dnf install wl-clipboard"
            echo "Wayland - Arch: sudo pacman -S wl-clipboard"
            exit 1
        fi
    fi
}

# Function to copy to clipboard based on OS
copy_to_clipboard() {
    local os
    os=$(get_os)

    check_dependencies "$os"

    case "$os" in
        macos)
            pbcopy
            ;;
        linux)
            if command -v wl-copy >/dev/null 2>&1; then
                wl-copy
            elif command -v xclip >/dev/null 2>&1; then
                xclip -selection clipboard
            elif command -v xsel >/dev/null 2>&1; then
                xsel --clipboard --input
            fi
            ;;
        *)
            echo "Unsupported operating system"
            exit 1
            ;;
    esac
}

# If no input is provided, read from stdin
if [ $# -eq 0 ]; then
    copy_to_clipboard
# If file is provided, cat it to clipboard
else
    cat "$@" | copy_to_clipboard
fi
