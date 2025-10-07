#!/usr/bin/env bash

# Check if we're on Darwin/macOS
if [[ "$(uname)" == "Darwin" ]]; then
  /usr/bin/tail -r "$@"
else
  # On Linux systems, use the real tac command
  command tac "$@"
fi
