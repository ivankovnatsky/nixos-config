#!/usr/bin/env bash

# Default values
ASSIGNEE="@me"
REVIEWER=""
LABEL=""
UPDATE="rebase"
DRAFT=""

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
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
done

GITHUB_TOKEN=$(rbw get https://github.com)
export GITHUB_TOKEN

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

# Create pull request
gh pr create \
    --assignee "$ASSIGNEE" \
    --head "$HEAD" \
    --title "$TITLE" \
    --base "$DEFAULT_BRANCH" \
    ${REVIEWER:+--reviewer "$REVIEWER"} \
    ${LABEL:+--label "$LABEL"} \
    ${DRAFT:+--draft}
