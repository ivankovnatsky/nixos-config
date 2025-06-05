#!/usr/bin/env bash

set -e

if [ $# -lt 1 ]; then
  echo "Usage: git-worktree-init <branch-name>" >&2
  exit 1
fi

BRANCH_NAME="$1"
GIT_ROOT=$(git rev-parse --show-toplevel)
WORKTREE_DIR=".git/__worktrees/$BRANCH_NAME"
FULL_PATH="$GIT_ROOT/$WORKTREE_DIR"

# Check if branch exists
if ! git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
  # Branch doesn't exist, create a new one
  git worktree add "$WORKTREE_DIR" -b "$BRANCH_NAME"
else
  # Branch exists, just add the worktree
  git worktree add "$WORKTREE_DIR" "$BRANCH_NAME"
fi

# Output the full path to the worktree
echo "$FULL_PATH"
