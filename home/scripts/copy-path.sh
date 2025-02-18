#!/usr/bin/env bash

# Function to display script usage
usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  abs     Copy absolute path of current directory"
    echo "  git     Copy path relative to git root"
    echo ""
    echo "Common options:"
    echo "  --help  Display this help message"
}

# Function to copy to clipboard based on OS
copy_to_clipboard() {
    local content="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo -n "$content" | pbcopy
    elif command -v xclip >/dev/null 2>&1; then
        # Linux with xclip
        echo -n "$content" | xclip -selection clipboard
    elif command -v wl-copy >/dev/null 2>&1; then
        # Linux with Wayland
        echo -n "$content" | wl-copy
    else
        echo "Error: No clipboard command found. Please install xclip or wl-copy."
        exit 1
    fi
    echo "Copied to clipboard: $content"
}

# Show help if no arguments or help flag
if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage
    exit 0
fi

COMMAND="$1"
shift

# Handle commands
case $COMMAND in
    abs)
        # Get the current working directory
        path=$(pwd)
        copy_to_clipboard "$path"
        ;;
    git)
        # Get the git root directory
        if ! git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
            echo "Error: Not in a git repository"
            exit 1
        fi

        # Get the current working directory
        current_path=$(pwd)

        # Get the relative path from git root
        relative_path=${current_path#"$git_root"}
        # Remove leading slash if present
        relative_path=${relative_path#/}

        # If path is empty (we're at root), use "."
        if [ -z "$relative_path" ]; then
            relative_path="."
        fi

        copy_to_clipboard "$relative_path"
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        usage
        exit 1
        ;;
esac
