#!/usr/bin/env bash
# Create a git worktree with a random two-word name based on main branch.

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: gwq-add"
  echo ""
  echo "Create a git worktree with a random two-word branch name based on main."
  echo "Uses gwq to manage the worktree and prints the full path on success."
  exit 0
fi

if [[ $# -gt 0 ]]; then
  echo "Error: gwq-add takes no arguments (branch names are generated randomly)" >&2
  echo "Usage: gwq-add" >&2
  exit 1
fi

WORD_FILE="/usr/share/dict/words"

if [[ ! -f "$WORD_FILE" ]]; then
  echo "Error: $WORD_FILE not found" >&2
  exit 1
fi

# Get two random lowercase words (4-8 chars, no apostrophes)
get_random_word() {
  grep -E "^[a-z]{4,8}$" "$WORD_FILE" | shuf -n 1
}

word1=$(get_random_word)
word2=$(get_random_word)
branch_name="${word1}-${word2}"

gwq add -b "$branch_name" >&2
gwq get "$branch_name"
