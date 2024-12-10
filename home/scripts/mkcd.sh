#!/usr/bin/env bash

# Check if directory name is provided
if [ -z "$1" ]; then
    echo "Usage: mkcd <directory-name>"
    exit 1
fi

# Create directory and cd into it
mkdir -p "$1" && cd "$1"
