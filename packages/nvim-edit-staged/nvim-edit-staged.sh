#!/usr/bin/env bash

set -euo pipefail

git_root=$(git rev-parse --show-toplevel)
staged_files=$(git diff --staged --name-only)

if [[ -z "$staged_files" ]]; then
  echo "No staged files"
  exit 0
fi

absolute_files=()
while IFS= read -r file; do
  absolute_files+=("$git_root/$file")
done <<<"$staged_files"

nvim "${absolute_files[@]}"
