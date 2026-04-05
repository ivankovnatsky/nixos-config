#!/usr/bin/env bash
# Merge feature worktree branch into the main one via fast-forward.

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: gwq-merge"
  echo ""
  echo "Rebases onto and fast-forward merges the current worktree branch into the main branch."
  exit 0
fi

gwq_json=$(gwq list --json)
main_tree_path=$(echo "${gwq_json}" | jq -r '.[] | select(.is_main == true) | .path')
main_branch=$(echo "${gwq_json}" | jq -r '.[] | select(.is_main == true) | .branch')
current_branch=$(git rev-parse --abbrev-ref HEAD)

if [[ "${current_branch}" == "${main_branch}" ]]; then
  echo "error: already on ${main_branch}, nothing to merge" >&2
  exit 1
fi

git rebase --autostash "${main_branch}"
git -C "${main_tree_path}" merge --ff-only "${current_branch}"
