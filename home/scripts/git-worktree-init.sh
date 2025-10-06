#!/usr/bin/env bash

set -e

# Check if branch name argument is provided
if [ -z "$1" ]; then
  echo "Error: Please provide a branch name" >&2
  echo "Usage: $(basename "$0") feature/BRANCH-NAME" >&2
  exit 1
fi

BRANCH_NAME="$1"
# Check if we're in a git repository
if ! GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo "Error: Not in a git repository" >&2
  exit 1
fi

WORKTREE_DIR=".git/__worktrees/$BRANCH_NAME"
FULL_PATH="$GIT_ROOT/$WORKTREE_DIR"

# Check if worktree already exists
if [ -d "$FULL_PATH" ]; then
  # Worktree exists, just output the path
  :
else
  # Check if branch exists
  if ! git show-ref --verify --quiet refs/heads/"$BRANCH_NAME"; then
    # Branch doesn't exist, create a new one
    git worktree add "$WORKTREE_DIR" -b "$BRANCH_NAME" >/dev/null 2>&1 || true
  else
    # Branch exists, just add the worktree
    git worktree add "$WORKTREE_DIR" "$BRANCH_NAME" >/dev/null 2>&1 || true
  fi
fi

# Output ONLY the full path to the worktree without any additional text
# This makes it compatible with fish shell's command substitution
echo -n "$FULL_PATH"
