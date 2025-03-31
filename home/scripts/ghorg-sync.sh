#!/usr/bin/env bash

# Show usage/help
show_help() {
    echo "Usage: $0 <organization_name>"
    echo
    echo "Syncs all repositories from the specified GitHub organization"
    echo
    echo "Arguments:"
    echo "  organization_name    Name of the GitHub organization to sync"
    echo
    echo "Example:"
    echo "  $0 my-org-name"
    exit 1
}

# Check if we have the required argument
if [ $# -ne 1 ]; then
    show_help
fi

# Check if GHORG is installed
if ! command -v ghorg &> /dev/null; then
    echo "Error: ghorg is not installed. Please install it first."
    exit 1
fi

# Get the organization name from argument
ORG_NAME="$1"

# Clone/sync the organization repos
ghorg clone "$ORG_NAME"
