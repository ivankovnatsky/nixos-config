#!/usr/bin/env bash

# ghq-cd - Use fzf to select and cd into a ghq-managed repository

if [[ -n "$1" ]]; then
  matches="$(ghq list | grep -F "$1")"
  match_count="$(echo "$matches" | grep -c .)"
  if [[ "$match_count" -eq 1 ]]; then
    selected_repo="$matches"
  else
    selected_repo="$(echo "$matches" | fzf --prompt='repo> ' --height 50% --layout=reverse --header=' Select a repository')"
  fi
else
  selected_repo="$(ghq list | fzf --prompt='repo> ' --height 50% --layout=reverse --header=' Select a repository')"
fi

if [[ -n "$selected_repo" ]]; then
  repo_path="$(ghq root)/$selected_repo"
  cd "$repo_path" || exit 1
  echo "Entered $selected_repo (exit to return)"
  exec "$SHELL"
fi
