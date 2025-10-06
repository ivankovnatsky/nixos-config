#!/bin/bash

# Script to transfer GitHub stars from one account to another using GitHub CLI

# Function to check if gh CLI is installed
check_gh_cli() {
  if ! command -v gh &>/dev/null; then
    echo "GitHub CLI (gh) is not installed. Please install it first."
    echo "Visit https://cli.github.com/ for installation instructions."
    exit 1
  fi
}

# Function to get starred repositories
get_starred_repos() {
  local username="$1"
  gh api --paginate "users/$username/starred" --jq '.[].full_name'
}

# Function to star repositories
star_repos() {
  local repo_list="$1"
  while IFS= read -r repo; do
    echo "Starring $repo"
    gh api --method PUT "user/starred/$repo" -H "Accept: application/vnd.github+json"
  done <<<"$repo_list"
}

# Function to unstar repositories
unstar_repos() {
  local repo_list="$1"
  while IFS= read -r repo; do
    echo "Unstarring $repo"
    gh api --method DELETE "user/starred/$repo" -H "Accept: application/vnd.github+json"
  done <<<"$repo_list"
}

# Main script
check_gh_cli

# Get the usernames
read -r -p "Enter the username of the account with the stars you want to transfer: " old_username
read -r -p "Enter the username of the account you want to transfer stars to: " new_username

# Get starred repos from old account
echo "Fetching starred repositories from $old_username..."
starred_repos=$(get_starred_repos "$old_username")

# Star repos in new account
echo "Please authenticate with the new account ($new_username)"
gh auth login
echo "Starring repositories in $new_username's account..."
star_repos "$starred_repos"

# Ask if user wants to unstar repos from old account
read -r -p "Do you want to unstar these repositories from the old account? (y/n): " unstar_choice
if [[ $unstar_choice == "y" || $unstar_choice == "Y" ]]; then
  echo "Please authenticate with the old account ($old_username)"
  gh auth login
  echo "Unstarring repositories from $old_username's account..."
  unstar_repos "$starred_repos"
  echo "Unstarring complete!"
fi

echo "Star transfer process complete!"
