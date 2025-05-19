#!/usr/bin/env bash

set -e

# Default organization if not specified by flags
DEFAULT_ORG=""
ORG="${DEFAULT_ORG}"

# Get today's date in YYYY-MM-DD format
TODAY=$(date +"%Y-%m-%d")

function usage() {
  echo "Usage: $0 [list|open] [options]"
  echo ""
  echo "Commands:"
  echo "  list            List PRs merged today"
  echo "  open            Open PRs merged today in browser"
  echo ""
  echo "Options:"
  echo "  -o, --org ORG   Specify GitHub organization (required)"
  echo "  -h, --help      Show this help message"
  exit 1
}

function list_prs() {
  # Ensure organization is specified
  if [ -z "${ORG}" ]; then
    echo "Error: Organization must be specified with -o or --org"
    usage
  fi

  echo "PRs merged today (${TODAY}) in ${ORG} from develop to main/master:"
  
  # Get repositories in the organization
  REPOS=$(gh repo list "${ORG}" --limit 20 --json name | jq -r '.[].name')
  
  # Find and display merged PRs
  for REPO in $REPOS; do
    # Search for PRs merged today from develop to main or master
    PRS=$(gh pr list --repo "${ORG}/${REPO}" --search "merged:${TODAY} base:main base:master head:develop" --state merged --json number,title,author,mergedAt,url,baseRefName,headRefName --limit 100)
    
    # Skip repositories with no merged PRs today
    if [ "$(echo "$PRS" | jq length)" -eq 0 ]; then
      continue
    fi
    
    # Display merged PRs
    echo "$PRS" | jq -r --arg repo "$REPO" '.[] | "\(.mergedAt) | \(.author.login) | \($repo) | #\(.number) | \(.headRefName) → \(.baseRefName) | \(.title) | \(.url)"'
  done | sort | column -t -s "|"
}

function open_prs() {
  # Ensure organization is specified
  if [ -z "${ORG}" ]; then
    echo "Error: Organization must be specified with -o or --org"
    usage
  fi

  echo "Finding PRs merged today (${TODAY}) in ${ORG} from develop to main/master..."
  
  # Temporary file to store URLs
  URL_FILE=$(mktemp)
  
  # Get repositories in the organization
  REPOS=$(gh repo list "${ORG}" --limit 20 --json name | jq -r '.[].name')
  
  # For each repository, collect URLs of PRs merged today
  for REPO in $REPOS; do
    # Search for PRs merged today from develop to main or master
    REPO_URLS=$(gh pr list --repo "${ORG}/${REPO}" --search "merged:${TODAY} base:main base:master head:develop" --state merged --json url --limit 100 | jq -r '.[].url')
    
    # Skip empty results
    if [ -z "$REPO_URLS" ]; then
      continue
    fi
    
    # Add URLs to the file
    echo "$REPO_URLS" >> "$URL_FILE"
    
    # Show found URLs
    echo "$REPO_URLS" | while read -r url; do
      echo "Found: $url"
    done
  done
  
  # Count URLs
  URL_COUNT=$(wc -l < "$URL_FILE" | tr -d ' ')
  
  # Check if we found any PRs
  if [ "$URL_COUNT" -eq 0 ]; then
    echo "No PRs found merged today from develop to main/master."
    rm "$URL_FILE"
    exit 0
  fi
  
  # Prompt user to confirm opening URLs
  echo ""
  echo "Found $URL_COUNT PRs. Open them in browser? (y/n)"
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Opening URLs in parallel..."
    
    # Determine the opener command based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS
      OPENER="open"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      # Linux
      OPENER="xdg-open"
    else
      # Fall back to OS-specific browser opener
      echo "Unsupported OS for parallel opening. Opening sequentially instead."
      while read -r url; do
        echo "Opening: $url"
        gh browse "$url"
      done < "$URL_FILE"
      rm "$URL_FILE"
      exit 0
    fi
    
    # Open all URLs in parallel using xargs (avoid useless use of cat)
    xargs -P 5 -I {} sh -c "echo Opening: {}; $OPENER {} > /dev/null 2>&1" < "$URL_FILE"
  else
    echo "Operation cancelled."
  fi
  
  # Clean up
  rm "$URL_FILE"
}

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
  echo "GitHub CLI (gh) is not installed. Please install it first."
  echo "Visit: https://cli.github.com/manual/installation"
  exit 1
fi

# Check if logged in
if ! gh auth status &> /dev/null; then
  echo "You are not logged in to GitHub CLI. Please login first."
  echo "Run: gh auth login"
  exit 1
fi

# No arguments provided
if [ $# -eq 0 ]; then
  usage
fi

# Parse command
COMMAND="$1"
shift

# Parse options
while [ $# -gt 0 ]; do
  case "$1" in
    -o|--org)
      ORG="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Execute command
case "${COMMAND}" in
  list)
    list_prs
    ;;
  open)
    open_prs
    ;;
  *)
    echo "Unknown command: ${COMMAND}"
    usage
    ;;
esac
