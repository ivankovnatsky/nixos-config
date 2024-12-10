#!/usr/bin/env bash

# Function to process GitHub URL and return appropriate part
strip_url() {
    local url="$1"
    # Remove trailing slash if present
    url="${url%/}"
    
    # Check if URL contains more than one slash after github.com
    if [[ "$url" =~ github\.com/[^/]+/[^/]+ ]]; then
        # If it's a full repo URL, strip to org/repo level
        echo "$url"
    else
        # If it's just an org URL, use as is
        echo "${url%/*}"
    fi
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

# Process the URL
STRIPPED_URL=$(strip_url "$URL")

# Use ghq to get the repository
ghq get --look "${STRIPPED_URL}"
