#!/usr/bin/env bash

# sesh-connect.sh - Interactive session manager connection script
# Usage: Called from tmux bind-key to show popup with session selection

selected_session="$(
    {
        echo "📁 New Session"
        sesh list --icons --hide-attached --hide-duplicates
    } | fzf --prompt='⚡ ' --height 50% --layout=reverse --header=' Pick a session' --ansi
)"

if [[ "$selected_session" == "📁 New Session" ]]; then
    echo "Starting new session..."
    sesh connect "$PWD"
elif [[ -n "$selected_session" ]]; then
    sesh connect "$selected_session"
else
    echo "No session selected, starting new session..."
    sesh connect "$PWD"
fi
