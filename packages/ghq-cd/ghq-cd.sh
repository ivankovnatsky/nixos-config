#!/usr/bin/env bash

# ghq-cd - Use fzf to select and cd into a ghq-managed repository

selected_repo="$(ghq list | fzf --prompt='repo> ' --height 50% --layout=reverse --header=' Select a repository')"

if [[ -n "$selected_repo" ]]; then
  repo_path="$(ghq root)/$selected_repo"
  cd "$repo_path" || exit 1
  echo "Entered $selected_repo (exit to return)"
  exec "$SHELL"
fi
