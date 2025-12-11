#!/usr/bin/env python3
"""GitHub PR management tool for creating and merging pull requests."""

import argparse
import os
import subprocess
import sys
import webbrowser
from dataclasses import dataclass


@dataclass
class Config:
    assignee: str = "@me"
    reviewer: str = ""
    label: str = ""
    update: str = "rebase"
    draft: bool = False
    strategy: str = "squash"
    admin: bool = False


def run_cmd(cmd: list[str], capture: bool = True) -> subprocess.CompletedProcess:
    """Run a command and return the result."""
    return subprocess.run(cmd, capture_output=capture, text=True)


def check_git_repo() -> bool:
    """Check if we're in a git repository."""
    result = run_cmd(["git", "rev-parse", "--is-inside-work-tree"])
    return result.returncode == 0


def get_current_branch() -> str:
    """Get the current git branch name."""
    result = run_cmd(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    return result.stdout.strip()


def get_default_branch() -> str:
    """Get the default branch name from origin."""
    result = run_cmd(["git", "symbolic-ref", "refs/remotes/origin/HEAD"])
    if result.returncode != 0:
        return "main"
    return result.stdout.strip().replace("refs/remotes/origin/", "")


def get_last_commit_message() -> str:
    """Get the last commit message."""
    result = run_cmd(["git", "log", "-1", "--pretty=format:%s"])
    return result.stdout.strip()


def open_url(url: str) -> None:
    """Open URL in browser."""
    webbrowser.open(url)


def unset_github_tokens() -> None:
    """Unset GitHub tokens to use gh CLI authentication."""
    os.environ.pop("GH_TOKEN", None)
    os.environ.pop("GITHUB_TOKEN", None)


def cmd_create(config: Config) -> int:
    """Create a new pull request."""
    title = get_last_commit_message()
    head = get_current_branch()
    default_branch = get_default_branch()

    # Update branch
    if config.update == "rebase":
        result = run_cmd(["git", "pull", "--rebase", "origin", default_branch], capture=False)
    else:
        result = run_cmd(["git", "pull", "origin", default_branch], capture=False)

    if result.returncode != 0:
        print("Failed to update branch")
        return 1

    # Push changes
    result = run_cmd(["git", "push", "--force-with-lease", "origin", head], capture=False)
    if result.returncode != 0:
        print("Failed to push changes")
        return 1

    # Build gh pr create command
    cmd = [
        "gh", "pr", "create",
        "--assignee", config.assignee,
        "--head", head,
        "--title", title,
        "--base", default_branch,
        "--fill",
    ]

    if config.reviewer:
        cmd.extend(["--reviewer", config.reviewer])
    if config.label:
        cmd.extend(["--label", config.label])
    if config.draft:
        cmd.append("--draft")
    else:
        cmd.append("--web")

    result = run_cmd(cmd, capture=False)
    if result.returncode == 0:
        print("Pull request created successfully!")
        return 0
    else:
        print("Failed to create pull request")
        return 1


def cmd_merge(config: Config) -> int:
    """Merge an existing pull request."""
    cmd = ["gh", "pr", "merge", f"--{config.strategy}"]
    if config.admin:
        cmd.append("--admin")

    result = run_cmd(cmd, capture=True)
    if result.returncode == 0:
        # Get PR URL
        url_result = run_cmd(["gh", "pr", "view", "--json", "url", "-q", ".url"])
        if url_result.returncode == 0:
            pr_url = url_result.stdout.strip()
            print("Pull request merged successfully!")
            print(f"View it here: {pr_url}")
            open_url(f"{pr_url}/files")
        return 0
    else:
        print("Failed to merge pull request:")
        print(result.stderr or result.stdout)
        return 1


def cmd_view() -> int:
    """View pull request files in browser."""
    result = run_cmd(["gh", "pr", "view", "--json", "url", "-q", ".url"])
    if result.returncode == 0:
        pr_url = result.stdout.strip()
        print("Opening pull request in browser...")
        open_url(f"{pr_url}/files")
        return 0
    else:
        print("Failed to get pull request URL. Are you in a PR branch?")
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(
        description="GitHub PR management tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Create command
    create_parser = subparsers.add_parser("create", help="Create a new pull request")
    create_parser.add_argument(
        "--assignee", default="@me",
        help="Specify the assignee for the pull request (default: @me)"
    )
    create_parser.add_argument(
        "--reviewers",
        help="Specify the reviewers for the pull request"
    )
    create_parser.add_argument(
        "--labels",
        help="Specify the label for the pull request"
    )
    create_parser.add_argument(
        "--update", choices=["rebase", "merge"], default="rebase",
        help="Specify the update strategy (default: rebase)"
    )
    create_parser.add_argument(
        "--draft", action="store_true",
        help="Create a draft pull request"
    )

    # Merge command
    merge_parser = subparsers.add_parser("merge", help="Merge an existing pull request")
    merge_parser.add_argument(
        "--strategy", choices=["squash", "merge", "rebase"], default="squash",
        help="Specify the merge strategy (default: squash)"
    )
    merge_parser.add_argument(
        "--admin", "--bypass", action="store_true",
        help="Use administrator privileges to bypass merge queue requirements"
    )

    # View command
    subparsers.add_parser("view", help="View pull request files in browser")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 0

    # Check if we're in a git repository
    if not check_git_repo():
        print("Error: Not in a git repository")
        return 1

    # Check if we're on main or master branch
    current_branch = get_current_branch()
    if current_branch in ("main", "master"):
        print(f"Error: You are on the {current_branch} branch. "
              "This script cannot be run on main or master branches.")
        return 1

    # Unset GitHub tokens to use gh CLI authentication
    unset_github_tokens()

    # Build config from args
    config = Config()

    if args.command == "create":
        config.assignee = args.assignee
        config.reviewer = args.reviewers or ""
        config.label = args.labels or ""
        config.update = args.update
        config.draft = args.draft
        return cmd_create(config)

    elif args.command == "merge":
        config.strategy = args.strategy
        config.admin = args.admin
        return cmd_merge(config)

    elif args.command == "view":
        return cmd_view()

    return 0


if __name__ == "__main__":
    sys.exit(main())
