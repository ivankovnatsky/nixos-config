#!/usr/bin/env bash

# Default values
ASSIGNEE="@me"
REVIEWER=""
LABEL=""
UPDATE="rebase"
DRAFT=""
BROWSER_APP="" # Browser name to override system default
STRATEGY="squash"
ADMIN_FLAG=""
COMMAND="" # create or merge

# Function to display script usage
usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  create    Create a new pull request"
    echo "  merge     Merge an existing pull request"
    echo "  view      View pull request files in browser"
    echo ""
    echo "Options for create:"
    echo "  --assignee <username>    Specify the assignee for the pull request (default: @me)"
    echo "  --reviewers <username>   Specify the reviewers for the pull request"
    echo "  --labels <label>         Specify the label for the pull request"
    echo "  --update <strategy>      Specify the update strategy (rebase or merge, default: rebase)"
    echo "  --draft                  Create a draft pull request"
    echo "  --browser <name>         Specify browser (e.g., 'Google Chrome' on macOS, 'firefox' on Linux)"
    echo ""
    echo "Options for merge:"
    echo "  --strategy <strategy>    Specify the merge strategy (squash, merge, or rebase, default: squash)"
    echo "  --admin                  Use administrator privileges to bypass merge queue requirements"
    echo "  --browser <name>         Specify browser (e.g., 'Google Chrome' on macOS, 'firefox' on Linux)"
    echo ""
    echo "Common options:"
    echo "  --help                   Display this help message"
}

# Function to open URL with the specified browser
open_url() {
    local url="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -n "$BROWSER_APP" ]; then
            open -a "$BROWSER_APP" "$url"
        else
            open "$url"
        fi
    else
        if [ -n "$BROWSER_APP" ]; then
            "$BROWSER_APP" "$url"
        else
            xdg-open "$url"
        fi
    fi
}

# Show help if no arguments or help flag
if [ $# -eq 0 ]; then
    usage
    exit 0
fi

COMMAND="$1"
shift

# Show help if requested for command
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage
    exit 0
fi

# Handle commands
case $COMMAND in
    create|merge|view)
        # Check if we're in a git repository
        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo "Error: Not in a git repository"
            exit 1
        fi
        ;;
    --help|-h)
        usage
        exit 0
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        usage
        exit 1
        ;;
esac

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
        --strategy)
            STRATEGY="$2"
            shift
            shift
            ;;
        --admin|--bypass)
            ADMIN_FLAG="--admin"
            shift
            ;;
        --browser)
            BROWSER_APP="$2"
            shift
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Check if we're on main or master branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
    echo "Error: You are on the $CURRENT_BRANCH branch. This script cannot be run on main or master branches."
    exit 1
fi

# Make sure we're not authenticated using personal tokens evaluated in shell environment.
unset GH_TOKEN
unset GITHUB_TOKEN

case $COMMAND in
    create)
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
        if gh pr create \
            --assignee "$ASSIGNEE" \
            --head "$HEAD" \
            --title "$TITLE" \
            --base "$DEFAULT_BRANCH" \
            ${REVIEWER:+--reviewer "$REVIEWER"} \
            ${LABEL:+--label "$LABEL"} \
            ${DRAFT:+--draft}; then
            PR_URL=$(gh pr view --json url -q .url)
            echo "Pull request created successfully!"
            echo "View it here: $PR_URL"
            open_url "$PR_URL/files"
        else
            echo "Failed to create pull request"
            exit 1
        fi
        ;;
        
    merge)
        # Merge PR
        if OUTPUT=$(gh pr merge "--$STRATEGY" "$ADMIN_FLAG" 2>&1); then
            PR_URL=$(gh pr view --json url -q .url)
            echo "Pull request merged successfully!"
            echo "View it here: $PR_URL"
            open_url "$PR_URL"
        else
            echo "Failed to merge pull request:"
            echo "$OUTPUT"
            exit 1
        fi
        ;;
        
    view)
        # Get PR URL and open in browser
        if PR_URL=$(gh pr view --json url -q .url 2>/dev/null); then
            echo "Opening pull request in browser..."
            open_url "$PR_URL/files"
        else
            echo "Failed to get pull request URL. Are you in a PR branch?"
            exit 1
        fi
        ;;
esac
