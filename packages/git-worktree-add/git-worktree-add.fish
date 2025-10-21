#!/usr/bin/env fish

# Configuration
set -g BRANCH_NAME_CHAR_LIMIT 35

# Check if branch name argument is provided
if test (count $argv) -ne 1
    echo "Error: Please provide a branch name" >&2
    echo "Usage: "(status filename)" feature/KEY-12345-description" >&2
    return 1
end

# Check if we're in a git repository
set git_root (git rev-parse --show-toplevel 2>/dev/null)
if test $status -ne 0
    echo "Error: Not in a git repository" >&2
    return 1
end

# If we're in a worktree, get the main repository path
set git_common_dir (git rev-parse --git-common-dir 2>/dev/null)
set real_git_root (string replace -r '/\.git$' '' "$git_common_dir")
if test -n "$real_git_root" -a "$real_git_root" != "$git_common_dir"
    set git_root $real_git_root
end

# Get the git dir (could be .git or a path to the actual git dir)
set git_dir (git rev-parse --git-dir 2>/dev/null)

# Get the actual .git directory path
if test -f "$git_root/.git"
    # If .git is a file (in case of worktrees or submodules), read the gitdir from it
    set git_dir_path (string trim (cat "$git_root/.git" | string replace -r '^gitdir: ' ''))
    # If the path is relative, make it absolute
    if not string match -q '/*' "$git_dir_path"
        set git_dir_path "$git_root/$git_dir_path"
    end
else
    # Normal case, .git is a directory
    set git_dir_path "$git_root/.git"
end

cd $git_root

# Detect the default branch
set default_branch (git symbolic-ref refs/remotes/origin/HEAD | string replace 'refs/remotes/origin/' '')
if test -z "$default_branch"
    echo "Error: Could not detect default branch" >&2
    return 1
end

# Checkout default branch and pull latest changes
git checkout $default_branch >/dev/null 2>&1
git pull origin $default_branch >/dev/null 2>&1

set original_branch $argv[1]

# Split the branch name into prefix (feature/) and the rest
set prefix_part (string match -r '^[^/]+/' $original_branch)
set name_part (string replace -r '^[^/]+/' '' $original_branch)

# If name is longer than the char limit, trim it
if test (string length $name_part) -gt $BRANCH_NAME_CHAR_LIMIT
    set trimmed_name (string sub -l $BRANCH_NAME_CHAR_LIMIT $name_part)
    set last_separator (string match -r '.*[- ]' $trimmed_name)
    if test -n "$last_separator"
        set name_part (string trim -c '-' $last_separator)
    else
        set name_part $trimmed_name
    end
end

# Get current SHA of default branch
set sha_suffix (git rev-parse --short=7 HEAD)

set branch_name "$prefix_part$name_part-$sha_suffix"
set worktree_parent_dir "__worktrees"
set worktree_dir "$git_dir_path/$worktree_parent_dir/$branch_name"

# Create worktree directory
mkdir -p "$git_dir_path/$worktree_parent_dir" >/dev/null 2>&1

# Try to create worktree or reuse existing
if git show-ref --verify --quiet "refs/heads/$branch_name"
    git worktree add "$worktree_dir" "$branch_name" >/dev/null 2>&1
else
    git worktree add -b "$branch_name" "$worktree_dir" $default_branch >/dev/null 2>&1
end

set final_path "$worktree_dir"
# Output without quotes, letting the shell handle the escaping
echo $final_path
