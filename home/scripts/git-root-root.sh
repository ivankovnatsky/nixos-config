#!/usr/bin/env bash

# Usage: cd (git-root-root)

if [ ! -e "$(git rev-parse --show-toplevel)/.git" ]; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

if [ -d "$(git rev-parse --show-toplevel)/.git" ]; then
    pwd
    exit 0
fi

# Read .git file directly into sed without using cat
MAIN_REPO=$(sed 's/\.git.*//' "$(git rev-parse --show-toplevel)/.git" | awk '{print $2}')
echo "$MAIN_REPO"
