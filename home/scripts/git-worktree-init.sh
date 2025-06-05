#!/usr/bin/env bash

set -e

BRANCH_NAME="$1"
GIT_ROOT=$(git rev-parse --show-toplevel)
WORKTREE_DIR=".git/__worktrees/$BRANCH_NAME"
FULL_PATH="$GIT_ROOT/$WORKTREE_DIR"

# Check if worktree already exists
if [ -d "$FULL_PATH" ]; then
  :
else
  # Check if branch exists
  if ! git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
    # Branch doesn't exist, create a new one
    git worktree add "$WORKTREE_DIR" -b "$BRANCH_NAME" 2>&1 >/dev/null || true
  else
    # Branch exists, just add the worktree
    git worktree add "$WORKTREE_DIR" "$BRANCH_NAME" 2>&1 >/dev/null || true
  fi
fi

# Output the full path to the worktree without any additional text
# This makes it compatible with fish shell's command substitution
echo "$FULL_PATH"
