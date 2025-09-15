#!/usr/bin/env bash

# Try to attach to the default rebuild session first
if tmux -S /tmp/tmux-1000/default has-session 2>/dev/null; then
    exec tmux -S /tmp/tmux-1000/default attach
else
    # Fallback to hostname-based session
    SESSION_NAME="${HOSTNAME:-$(hostname)}"
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        exec tmux attach -t "$SESSION_NAME"
    else
        echo "No tmux session found at /tmp/tmux-1000/default or session '$SESSION_NAME'"
        echo "Creating new session '$SESSION_NAME'..."
        exec tmux new-session -s "$SESSION_NAME"
    fi
fi