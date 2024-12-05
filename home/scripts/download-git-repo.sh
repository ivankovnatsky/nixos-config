#!/usr/bin/env bash

# Function to strip URL to the last forward slash
strip_url() {
    local url="$1"
    echo "${url%/*}"
}

# Check if URL is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <repository-url>"
    exit 1
fi

# Store all arguments in an array
args=("$@")

# Get the provided URL and handle special characters
URL="${args[0]}"

# Strip the URL to the last forward slash
STRIPPED_URL=$(strip_url "$URL")

# Use ghq to get the repository with proper quoting
ghq get --look "${STRIPPED_URL}"
