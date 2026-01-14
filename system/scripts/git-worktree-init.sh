#!/usr/bin/env bash

set -e

show_help() {
  echo "Usage: $(basename "$0") <branch-name>"
  echo ""
  echo "Create or navigate to a git worktree for the specified branch."
  echo ""
  echo "Arguments:"
  echo "  branch-name    The branch name for the worktree (e.g., feature/TICKET-123)"
  echo ""
  echo "Options:"
  echo "  -h, --help     Show this help message"
  echo ""
  echo "The worktree is created at .git/__worktrees/<branch-name> relative to the"
  echo "repository root. If the branch doesn't exist, it will be created."
  echo ""
  echo "Example:"
  echo "  $(basename "$0") feature/DOPS-12345"
}

# Handle help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  show_help
  exit 0
fi

# Check if branch name argument is provided
if [ -z "$1" ]; then
  echo "Error: Please provide a branch name" >&2
  echo "" >&2
  show_help >&2
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
