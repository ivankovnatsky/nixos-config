#!/usr/bin/env bash

# Add a new task and immediately open it in the editor for details

if ! command -v task &>/dev/null; then
  echo "Error: taskwarrior is not installed"
  exit 1
fi

task add "${1:-new task}" && EDITOR="${EDITOR:-nvim}" task "$(task +LATEST uuids)" edit
