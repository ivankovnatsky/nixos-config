#!/usr/bin/env bash

# Create a new tmux session called 'a3-monitoring'
SESSION_NAME="a3-temperatures"

# Kill existing session if it exists
tmux kill-session -t "$SESSION_NAME" 2>/dev/null

# Create new session with first pane running btop
tmux new-session -d -s "$SESSION_NAME" -c "$HOME" 'btop'

# Split vertically (create bottom pane for temperatures)
tmux split-window -v -t "$SESSION_NAME:0" -c "$HOME" 'temperatures'

# Split the bottom pane horizontally (create nvidia-smi pane next to temperatures)
tmux split-window -h -t "$SESSION_NAME:0.1" -c "$HOME" 'watch nvidia-smi'

# Resize panes: make btop (pane 0) take 60% of height
tmux resize-pane -t "$SESSION_NAME:0.0" -y 60%

# Make the bottom panes equal width (50% each)
tmux resize-pane -t "$SESSION_NAME:0.1" -x 50%
tmux resize-pane -t "$SESSION_NAME:0.2" -x 50%

# Select the btop pane
tmux select-pane -t "$SESSION_NAME:0.0"

# Attach to session
tmux attach-session -t "$SESSION_NAME"
