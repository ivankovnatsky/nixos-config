#!/usr/bin/env python3

from jira import JIRA
import sys
import os

def search_filters(query=None):
    """Search for Jira filters"""

    # Get Jira config from environment
    server = os.getenv('JIRA_SERVER')
    email = os.getenv('JIRA_EMAIL')
    token = os.getenv('JIRA_API_TOKEN')

    if not all([server, email, token]):
        print("Error: Set JIRA_SERVER, JIRA_EMAIL, and JIRA_API_TOKEN in environment", file=sys.stderr)
        sys.exit(1)

    # Initialize Jira with basic auth (email + API token)
    jira = JIRA(server=server, basic_auth=(email, token))

    # Get all filters accessible to the user
    filters = jira.favourite_filters()

    if query:
        # Filter by query
        filters = [f for f in filters if query.lower() in f.name.lower()]

    # Display filters
    for f in filters:
        print(f"{f.id}: {f.name}")
        print(f"  Owner: {f.owner.displayName}")
        print(f"  JQL: {f.jql}")
        print()

def main():
    if len(sys.argv) > 1:
        search_filters(sys.argv[1])
    else:
        search_filters()

if __name__ == "__main__":
    main()
