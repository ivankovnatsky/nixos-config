#!/usr/bin/env bash

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Get current branch
current_branch=$(git branch --show-current)

# Get list of local branches (excluding current) and select with fzf
selected_branch=$(
    git branch --format='%(refname:short)' | \
    grep -v "^${current_branch}$" | \
    fzf --height=20 --layout=reverse --border \
        --prompt="Branch: " \
        --preview="git log --oneline --graph --decorate --color=always {} -20" \
        --preview-window=right:50%
)

# Switch to selected branch if one was chosen
if [ -n "$selected_branch" ]; then
    # Try git switch first (newer command), fall back to checkout
    if git switch "$selected_branch" 2>/dev/null; then
        echo "Switched to branch: $selected_branch"
    elif git checkout "$selected_branch"; then
        echo "Checked out branch: $selected_branch"
    else
        echo "Error: Failed to switch to branch: $selected_branch"
        exit 1
    fi
fi
