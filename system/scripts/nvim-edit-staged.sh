#!/usr/bin/env bash

set -euo pipefail

staged_files=$(git diff --staged --name-only)

if [[ -z "$staged_files" ]]; then
    echo "No staged files"
    exit 0
fi

# shellcheck disable=SC2086
nvim $staged_files
