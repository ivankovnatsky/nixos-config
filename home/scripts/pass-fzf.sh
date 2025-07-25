#!/usr/bin/env bash

set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"

selected=$(find "$PASSWORD_STORE_DIR" -name "*.gpg" -type f | \
    sed "s|.*/${PASSWORD_STORE_DIR##*/}/||; s|\.gpg$||" | \
    fzf --prompt="Select item: " --height=40% --border \
)

if [[ -n "$selected" ]]; then
    echo "$selected"
    pass show -c "$selected"
fi
