#!/usr/bin/env bash
# Jump to the most recently created git worktree.

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: gwq-cd"
  echo ""
  echo "Print the path of the most recently created worktree (excluding main)."
  echo "Use with: cd \$(gwq-cd)"
  exit 0
fi

path=$(gwq list --json | jq -r '
  [ .[] | select(.is_main == false) ]
  | sort_by(.created_at)
  | last
  | .path
')

if [[ -z "$path" || "$path" == "null" ]]; then
  echo "Error: no worktrees found" >&2
  exit 1
fi

echo "$path"
