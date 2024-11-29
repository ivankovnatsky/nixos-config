#!/usr/bin/env fish

# Configuration
set -g BRANCH_NAME_CHAR_LIMIT 35

# Check if branch name argument is provided
if test (count $argv) -ne 1
    echo "Error: Please provide a branch name"
    echo "Usage: "(status filename)" feature/KEY-12345-description"
    return 1
end

# Check if we're in a git repository
set git_root (git rev-parse --show-toplevel 2>/dev/null)
if test $status -ne 0
    echo "Error: Not in a git repository"
    return 1
end

# Check if .git directory exists
if not test -d "$git_root/.git"
    echo "Error: .git directory not found"
    return 1
end

# Go to git root
cd $git_root

# Detect the default branch
set default_branch (git symbolic-ref refs/remotes/origin/HEAD | string replace 'refs/remotes/origin/' '')
if test -z "$default_branch"
    echo "Error: Could not detect default branch"
    return 1
end

# Checkout default branch and pull latest changes
git checkout $default_branch
git pull origin $default_branch

# Store branch name
set original_branch $argv[1]

# Split the branch name into prefix (feature/) and the rest
set prefix_part (string match -r '^[^/]+/' $original_branch)
set name_part (string replace -r '^[^/]+/' '' $original_branch)

# If name is longer than the char limit, trim it to the last complete word
if test (string length $name_part) -gt $BRANCH_NAME_CHAR_LIMIT
    # Get first N chars and trim to last complete word
    set trimmed_name (string sub -l $BRANCH_NAME_CHAR_LIMIT $name_part)
    # Find the last occurrence of hyphen or space
    set last_separator (string match -r '.*[- ]' $trimmed_name)

    if test -n "$last_separator"
        # Remove trailing hyphen if present
        set name_part (string trim -c '-' $last_separator)
    else
        set name_part $trimmed_name
    end
end

# Reconstruct the branch name
set branch_name "$prefix_part$name_part"
# Use the processed branch name for the worktree directory
set worktree_dir "__worktrees/$branch_name"

# Create worktree directory if it doesn't exist
mkdir -p "$git_root/__worktrees"

# Create worktree with new branch directly
if git worktree list | grep -q "$worktree_dir"
    echo "Error: Worktree already exists at: $worktree_dir"
    return 1
end

# Try to create worktree, handling existing branch case
if git show-ref --verify --quiet "refs/heads/$branch_name"
    # Branch exists, try to reuse it
    git worktree add "$worktree_dir" "$branch_name"
else
    # Create new branch and worktree
    git worktree add -b "$branch_name" "$worktree_dir" $default_branch
end

if test $status -eq 0
    cd "$worktree_dir"
    echo "Successfully created worktree at: $worktree_dir"
    echo "Branch: $branch_name"
    # Output the path without using printf %q
    echo "$git_root/$worktree_dir"
else
    echo "Error: Failed to create worktree"
    return 1
end
