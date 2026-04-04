#!/usr/bin/env bash
# Purge gwq worktrees whose branches are fully merged into their main branch.

set -euo pipefail

DRY_RUN=false

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: gwq-purge [--dry-run]"
  echo ""
  echo "Remove gwq worktrees whose branches are fully merged into main."
  echo "Skips the current worktree and main worktrees."
  echo ""
  echo "Options:"
  echo "  --dry-run, -n   Show what would be removed without removing"
  exit 0
fi

if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
  DRY_RUN=true
fi

current_dir=$(pwd -P)

gwq list --json -g | jq -c '.[] | select(.is_main == false)' | while read -r entry; do
  wt_path=$(echo "$entry" | jq -r '.path')
  branch=$(echo "$entry" | jq -r '.branch')

  # Skip the worktree we're currently in
  if [[ "$current_dir" == "$wt_path"* ]]; then
    echo "skip (current): $branch"
    continue
  fi

  # Find the main branch for this repo by looking at the bare/main worktree
  repo_root=$(git -C "$wt_path" worktree list --porcelain |
    grep -A0 '^worktree ' | head -1 | sed 's/^worktree //')
  main_branch=$(git -C "$repo_root" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null |
    sed 's|refs/remotes/origin/||') || true

  if [[ -z "$main_branch" ]]; then
    main_branch="main"
  fi

  # Check if the branch is fully merged into the main branch
  # A branch is merged if merge-base --is-ancestor succeeds
  if git -C "$wt_path" merge-base --is-ancestor "$branch" "$main_branch" 2>/dev/null; then
    if $DRY_RUN; then
      echo "would remove: $branch ($wt_path)"
    else
      echo "removing: $branch ($wt_path)"
      gwq remove -g -b "$branch"
    fi
  else
    echo "skip (not merged): $branch"
  fi
done
