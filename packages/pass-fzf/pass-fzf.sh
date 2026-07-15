#!/usr/bin/env bash

set -euo pipefail

selected=$(
  gopass list --flat |
    fzf --prompt="Select item: " --height=40% --border
)

if [[ -n "$selected" ]]; then
  echo "$selected"
  gopass show --clip "$selected"
fi
