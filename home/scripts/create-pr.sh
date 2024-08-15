#!/usr/bin/env bash

# Default values
ASSIGNEE="@me"
REVIEWER=""
LABEL=""
UPDATE="rebase"
DRAFT=""

# Function to display script usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --assignee <username>    Specify the assignee for the pull request (default: @me)"
    echo "  --reviewers <username>   Specify the reviewers for the pull request"
    echo "  --labels <label>         Specify the label for the pull request"
    echo "  --update <strategy>      Specify the update strategy (rebase or merge, default: rebase)"
    echo "  --draft                  Create a draft pull request"
    echo "  --help                   Display this help message"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    --assignee)
        ASSIGNEE="$2"
        shift
        shift
        ;;
    --reviewers)
        REVIEWER="$2"
        shift
        shift
        ;;
    --labels)
        LABEL="$2"
        shift
        shift
        ;;
    --update)
        UPDATE="$2"
        shift
        shift
        ;;
    --draft)
        DRAFT="true"
        shift
        ;;
    --help)
        usage
        exit 0
        ;;
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
done

TITLE="$(git log -1 --pretty=format:%s)"
HEAD="$(git rev-parse --abbrev-ref HEAD)"

# Determine the default branch
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

# Update main branch
if [[ $UPDATE == "rebase" ]]; then
    git pull --rebase origin "$DEFAULT_BRANCH"
else
    git pull origin "$DEFAULT_BRANCH"
fi

# Push changes
git push --force-with-lease origin "$HEAD"

# Make sure we're not authenticated using personal tokens evaluated in shell environment.
unset GH_TOKEN
unset GITHUB_TOKEN

# Create pull request
gh pr create \
    --assignee "$ASSIGNEE" \
    --head "$HEAD" \
    --title "$TITLE" \
    --base "$DEFAULT_BRANCH" \
    ${REVIEWER:+--reviewer "$REVIEWER"} \
    ${LABEL:+--label "$LABEL"} \
    ${DRAFT:+--draft}

# Open PR right away to verify everything is in order.
gh pr view --web
