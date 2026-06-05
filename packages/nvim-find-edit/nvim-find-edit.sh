#!/usr/bin/env bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: nvim-find-edit <pattern>" >&2
  exit 1
fi

pattern="$1"

mapfile -t files < <(rg -l -- "$pattern")

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No files found matching: $pattern" >&2
  exit 1
fi

escaped=$(printf '%s' "$pattern" | sed 's|/|\\/|g')
nvim "${files[@]}" +"/$escaped"
