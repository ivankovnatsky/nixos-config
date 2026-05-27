#!/usr/bin/env bash
# Merge feature worktree branch into the main one via fast-forward.

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: gwq-merge"
  echo ""
  echo "Rebases onto and fast-forward merges the current worktree branch into the main branch."
  echo "On success, removes the worktree and its branch."
  exit 0
fi

gwq_json=$(gwq list --json)
main_tree_path=$(echo "${gwq_json}" | jq -r '.[] | select(.is_main == true) | .path')
main_branch=$(echo "${gwq_json}" | jq -r '.[] | select(.is_main == true) | .branch')
current_branch=$(git rev-parse --abbrev-ref HEAD)
current_tree_path=$(echo "${gwq_json}" | jq -r --arg br "${current_branch}" '.[] | select(.branch == $br) | .path')

if [[ "${current_branch}" == "${main_branch}" ]]; then
  echo "error: already on ${main_branch}, nothing to merge" >&2
  exit 1
fi

stash_before=$(git stash list | wc -l)

git rebase --autostash "${main_branch}"
git -C "${main_tree_path}" merge --ff-only "${current_branch}"

stash_after=$(git stash list | wc -l)
if (( stash_after > stash_before )); then
  echo "warning: autostash pop failed; your changes are in 'git stash list' (run 'git stash pop')" >&2
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "note: merge to ${main_branch} succeeded; worktree kept because it has uncommitted changes" >&2
  exit 0
fi

cd "${main_tree_path}"
gwq remove "${current_tree_path}" -b
