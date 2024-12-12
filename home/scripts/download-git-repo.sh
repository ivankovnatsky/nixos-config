#!/usr/bin/env bash

# Function to process GitHub URL and return appropriate part
strip_url() {
    local url="$1"
    # Remove trailing slash if present
    url="${url%/}"
    
    # Only process github.com URLs
    if [[ "$url" =~ ^https://github\.com/ ]]; then
        # Check if URL contains more than one slash after github.com
        if [[ "$url" =~ github\.com/([^/]+/[^/]+) ]]; then
            # Extract just the org/repo part using the regex match
            echo "https://github.com/${BASH_REMATCH[1]}"
        else
            # If it's just an org URL, use as is
            echo "${url%/*}"
        fi
    else
        # For non-github URLs, return as is
        echo "$url"
    fi
}

# Get base directory from ghq config or use default
GHQ_ROOT=$(ghq root)

# Function to get the repository directory path
get_repo_path() {
    local url="$1"
    # First strip the URL to base repo URL
    url=$(strip_url "$url")
    # Then convert github.com/org/repo format to filesystem path
    local repo_path="${url#https://}"
    echo "${GHQ_ROOT}/${repo_path}"
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

# Try to clone (might fail if exists, that's ok)
ghq get "${STRIPPED_URL}" >/dev/null 2>&1 || true

# Get the directory path
REPO_PATH=$(get_repo_path "${STRIPPED_URL}")

# Instead of cd-ing, print the cd command for fish to evaluate
echo "cd ${REPO_PATH}"
