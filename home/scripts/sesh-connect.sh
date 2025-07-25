#!/usr/bin/env bash

# sesh-connect.sh - Interactive session manager connection script
# Usage: Called from tmux bind-key to show popup with session selection

sesh connect "$(
    sesh list -i | \
        gum filter --limit 1 --no-sort --fuzzy \
            --placeholder ' Pick a session' --height 50 --prompt='⚡ '
)"
