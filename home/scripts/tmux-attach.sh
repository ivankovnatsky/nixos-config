#!/usr/bin/env bash

# List tmux sessions and add option to create new session
session=$(
  {
    echo "++ Create new session ++"
    tmux list-sessions -F "#{session_name}" 2>/dev/null
  } | fzf --height=10 --layout=reverse --border --prompt="Select tmux session: "
)

# Handle the selection
if [ -n "$session" ]; then
  if [ "$session" = "++ Create new session ++" ]; then
    # Prompt for new session name
    read -p "Enter new session name: " new_session_name
    if [ -n "$new_session_name" ]; then
      tmux new-session -s "$new_session_name"
    fi
  else
    tmux attach-session -t "$session"
  fi
fi
