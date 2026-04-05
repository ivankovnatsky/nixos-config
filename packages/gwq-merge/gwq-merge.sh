#!/usr/bin/env bash
# Merge feature worktree branch into the main one via fast-forward.

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: gwq-merge"
  echo ""
  echo "Fast-forward merges the current worktree branch into main."
  exit 0
fi

main_tree_path=$(gwq list --json | jq -r '.[0].path')
current_branch=$(git rev-parse --abbrev-ref HEAD)

git -C "${main_tree_path}" merge --ff-only "${current_branch}"
