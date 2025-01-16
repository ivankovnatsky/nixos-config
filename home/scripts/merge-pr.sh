#!/usr/bin/env bash

# Default values
STRATEGY="squash"
ADMIN_FLAG=""

# Function to display script usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --strategy <strategy>    Specify the merge strategy (squash, merge, or rebase, default: squash)"
    echo "  --admin                  Use administrator privileges to bypass merge queue requirements"
    echo "  --help                   Display this help message"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --strategy)
            STRATEGY="$2"
            shift
            shift
            ;;
        --admin)
            ADMIN_FLAG="--admin"
            shift
            ;;
        --bypass)
            ADMIN_FLAG="--admin"
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Check if we're on main or master branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
    echo "Error: You are on the $CURRENT_BRANCH branch. This script cannot be run on main or master branches."
    exit 1
fi

# Make sure we're not authenticated using personal tokens evaluated in shell environment.
unset GH_TOKEN
unset GITHUB_TOKEN

# Merge PR
gh pr merge "--${STRATEGY}" "${ADMIN_FLAG}"

# Open PR right away to verify everything is in order.
gh pr view --json url --jq .url | xargs -I {} open "{}/files"
