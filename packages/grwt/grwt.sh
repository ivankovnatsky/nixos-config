#!/usr/bin/env bash

# grwt - Select a ghq repo and create a worktree in it

set -euo pipefail

if [[ -n "${1:-}" ]]; then
  matches="$(ghq list | grep -F -e "$1" || true)"
  if [[ -z "$matches" ]]; then
    echo "No repo matched '$1'" >&2
    exit 1
  fi
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
  worktree_path="$(gwq-add)"
  cd "$worktree_path" || exit 1
  echo "Entered worktree for $selected_repo (exit to return)"
  exec "$SHELL"
fi
