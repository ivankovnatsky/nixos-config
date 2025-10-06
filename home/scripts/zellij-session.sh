#!/usr/bin/env bash

# zellij-session.sh - Simple zellij session manager
# Usage: zellij-session [session_name]
#   - If session_name provided, attach to or create that session
#   - If no args, show interactive session picker

set -euo pipefail

# Function to list active sessions with formatting
list_sessions() {
  zellij list-sessions --short 2>/dev/null | while read -r session_name; do
    if [[ -n "$session_name" ]]; then
      echo "🔗 $session_name"
    fi
  done
}

# Function to get raw session names
get_session_names() {
  zellij list-sessions --short 2>/dev/null
}

# Function to create or attach to session
connect_session() {
  local session_name="$1"

  if get_session_names | grep -q "^$session_name$"; then
    echo "Attaching to existing session: $session_name"
    zellij attach "$session_name"
  else
    echo "Creating new session: $session_name"
    # Try to create, if it fails (already exists), attach instead
    if ! zellij --session "$session_name" 2>/dev/null; then
      echo "Session exists, attaching instead..."
      zellij attach "$session_name"
    fi
  fi
}

# Main logic
if [[ $# -eq 0 ]]; then
  # Interactive mode
  echo "Zellij Session Manager"
  echo "====================="

  # Show current sessions
  sessions=$(list_sessions)

  if [[ -n "$sessions" ]]; then
    echo "Active sessions:"
    echo "$sessions"
    echo ""
  fi

  # Show options
  selected="$(
    {
      if [[ -n "$sessions" ]]; then
        echo "$sessions"
      fi
      echo "📁 New session ($(basename "$PWD"))"
      echo "📁 New session (custom name)"
      echo "❌ Exit"
    } | fzf --prompt='⚡ Select: ' --height 50% --layout=reverse --header=' Zellij Session Manager' --ansi
  )"

  case "$selected" in
  "📁 New session ($(basename "$PWD"))")
    connect_session "$(basename "$PWD")"
    ;;
  "📁 New session (custom name)")
    read -r -p "Enter session name: " custom_name
    if [[ -n "$custom_name" ]]; then
      connect_session "$custom_name"
    else
      echo "No name provided, using directory name"
      connect_session "$(basename "$PWD")"
    fi
    ;;
  "❌ Exit")
    exit 0
    ;;
  "")
    echo "No selection made"
    exit 1
    ;;
  *)
    # Extract session name from formatted output
    session_name="${selected#🔗 }"
    connect_session "$session_name"
    ;;
  esac
else
  # Direct session name provided
  connect_session "$1"
fi
