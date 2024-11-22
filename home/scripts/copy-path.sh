#!/usr/bin/env bash

# Get the current working directory
path=$(pwd)

# Detect OS and use appropriate clipboard command
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo -n "$path" | pbcopy
elif command -v xclip >/dev/null 2>&1; then
    # Linux with xclip
    echo -n "$path" | xclip -selection clipboard
elif command -v wl-copy >/dev/null 2>&1; then
    # Linux with Wayland
    echo -n "$path" | wl-copy
else
    echo "Error: No clipboard command found. Please install xclip or wl-copy."
    exit 1
fi

echo "Copied to clipboard: $path" 
