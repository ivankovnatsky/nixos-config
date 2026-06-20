#!/usr/bin/env bash
# Merge feature worktree branch into the main one via fast-forward.

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: gwq-merge [tree-name]"
  echo ""
  echo "Rebases onto and fast-forward merges the current (or named) worktree branch into the main branch."
  echo "On success, removes the worktree and its branch."
  exit 0
fi

gwq_json=$(gwq list --json)
main_tree_path=$(echo "${gwq_json}" | jq -r '.[] | select(.is_main == true) | .path')
main_branch=$(echo "${gwq_json}" | jq -r '.[] | select(.is_main == true) | .branch')

if [[ -n "${1:-}" ]]; then
  arg="$1"
  target_branch=$(echo "${gwq_json}" | jq -r --arg a "${arg}" \
    '.[] | select(.is_main == false) | select(.branch == $a or (.path | contains($a))) | .branch' | head -1)
  target_tree_path=$(echo "${gwq_json}" | jq -r --arg a "${arg}" \
    '.[] | select(.is_main == false) | select(.branch == $a or (.path | contains($a))) | .path' | head -1)
  if [[ -z "${target_branch}" ]]; then
    echo "error: no worktree found matching '${arg}'" >&2
    exit 1
  fi
else
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  if [[ "${current_branch}" == "${main_branch}" ]]; then
    echo "error: already on ${main_branch}, nothing to merge" >&2
    exit 1
  fi
  target_branch="${current_branch}"
  target_tree_path=$(echo "${gwq_json}" | jq -r --arg br "${target_branch}" '.[] | select(.branch == $br) | .path' | head -1)
  if [[ -z "${target_tree_path}" ]]; then
    echo "error: current branch '${current_branch}' not found in gwq worktree list" >&2
    exit 1
  fi
fi

stash_before=$(git -C "${target_tree_path}" stash list | wc -l)

git -C "${target_tree_path}" rebase --autostash "${main_branch}"
git -C "${main_tree_path}" merge --ff-only "${target_branch}"

stash_after=$(git -C "${target_tree_path}" stash list | wc -l)
if ((stash_after > stash_before)); then
  echo "warning: autostash pop failed; your changes are in 'git stash list' (run 'git stash pop')" >&2
fi

if [[ -n "$(git -C "${target_tree_path}" status --porcelain)" ]]; then
  echo "note: merge to ${main_branch} succeeded; worktree kept because it has uncommitted changes" >&2
  exit 0
fi

cd "${main_tree_path}"
gwq remove "${target_tree_path}" -b
