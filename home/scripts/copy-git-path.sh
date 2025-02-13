#!/usr/bin/env bash

# Get the git root directory
git_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ $? -ne 0 ]; then
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

# Detect OS and use appropriate clipboard command
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo -n "$relative_path" | pbcopy
elif command -v xclip >/dev/null 2>&1; then
    # Linux with xclip
    echo -n "$relative_path" | xclip -selection clipboard
elif command -v wl-copy >/dev/null 2>&1; then
    # Linux with Wayland
    echo -n "$relative_path" | wl-copy
else
    echo "Error: No clipboard command found. Please install xclip or wl-copy."
    exit 1
fi

echo "Copied to clipboard: $relative_path"
