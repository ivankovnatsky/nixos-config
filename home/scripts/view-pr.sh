#!/usr/bin/env bash

# Make sure we're not authenticated using personal tokens evaluated in shell environment.
unset GH_TOKEN
unset GITHUB_TOKEN

# Check if we're on main or master branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
    echo "Error: You are on the $CURRENT_BRANCH branch. This script cannot be run on main or master branches."
    exit 1
fi

# Open PR files in browser
gh pr view --json url --jq .url | xargs -I {} open "{}/files" 
