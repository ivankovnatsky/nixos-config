#!/usr/bin/env bash

if [ ! -e "$(git rev-parse --show-toplevel)/.git" ]; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

if [ -d "$(git rev-parse --show-toplevel)/.git" ]; then
    pwd
    exit 0
fi

MAIN_REPO=$(cat $(git rev-parse --show-toplevel)/.git | sed 's/\.git.*//' | awk '{print $2}')
echo "$MAIN_REPO"
