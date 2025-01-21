#!/usr/bin/env bash

# Exit on error
set -e

# Store the original directory
original_dir=$(pwd)

# Function to clean up on exit
cleanup() {
    cd "$original_dir"
}

# Register cleanup function
trap cleanup EXIT

# Process immediate subdirectories in parallel
/bin/ls -1 | \
parallel --will-cite --jobs 4 \
'
    if [ -d "{}" ] && [ -d "{}/.git" ]; then
        cd "{}" 2>/dev/null || exit 1
        
        # Get current branch name, handling detached HEAD state
        branch=$(git symbolic-ref -q HEAD || git rev-parse --short HEAD)
        branch=${branch#refs/heads/}
        
        echo "Updating $(pwd) (branch/commit: $branch)"

        # Fetch all branches
        git fetch origin || {
            echo "Warning: Failed to fetch from origin in $(pwd)"
            exit 0
        }

        # Only try to pull if we are on a branch (not in detached HEAD)
        if git symbolic-ref -q HEAD > /dev/null; then
            if git ls-remote --heads origin "$branch" | grep -q "$branch"; then
                git pull origin "$branch" || echo "Warning: Failed to pull $branch in $(pwd)"
            else
                echo "Warning: Branch $branch does not exist on remote in $(pwd)"
            fi
        else
            echo "Note: Repository is in detached HEAD state at commit $branch, skipping pull"
        fi

        cd "$OLDPWD"
    fi
'

echo "All repositories updated"
