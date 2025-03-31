#!/usr/bin/env bash

set -euo pipefail

copy() {
    if [[ $(uname) == "Darwin" ]]; then
        tr -d '\n' | pbcopy
    else
        if ! command -v xclip >/dev/null 2>&1; then
            echo "Error: xclip is not installed. Please install it first."
            exit 1
        fi
        tr -d '\n' | xclip -selection clipboard
    fi
}

if [[ $# -eq 0 ]]; then
    git branch --show-current
    exit 0
fi

case "$1" in
    copy)
        current_branch=$(git branch --show-current)
        if [[ -n "$current_branch" ]]; then
            echo "$current_branch" | copy
            echo "Branch name '$current_branch' copied to clipboard."
        else
            echo "Error: Not in a git repository or no current branch."
            exit 1
        fi
        ;;
    *)
        echo "Usage: $(basename "$0") [copy]"
        echo "  copy    Copy current branch name to clipboard"
        exit 1
        ;;
esac
