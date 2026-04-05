#!/usr/bin/env python3
"""GitHub PR management tool for creating and merging pull requests."""

import os
import subprocess
import sys
import webbrowser
from dataclasses import dataclass

import click


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


def open_pr_in_browser(path: str = "") -> None:
    """Get current PR URL and open in browser."""
    result = run_cmd(["gh", "pr", "view", "--json", "url", "-q", ".url"])
    if result.returncode == 0:
        url = result.stdout.strip()
        if path:
            url = f"{url}/{path}"
        open_url(url)


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
        result = run_cmd(
            ["git", "pull", "--rebase", "origin", default_branch], capture=False
        )
    else:
        result = run_cmd(["git", "pull", "origin", default_branch], capture=False)

    if result.returncode != 0:
        click.echo("Failed to update branch")
        return 1

    # Push changes
    result = run_cmd(
        ["git", "push", "--force-with-lease", "origin", head], capture=False
    )
    if result.returncode != 0:
        click.echo("Failed to push changes")
        return 1

    # Build gh pr create command
    cmd = [
        "gh",
        "pr",
        "create",
        "--assignee",
        config.assignee,
        "--head",
        head,
        "--title",
        title,
        "--base",
        default_branch,
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
        click.echo("Pull request created successfully!")
        if config.draft:
            open_pr_in_browser()
        return 0
    else:
        click.echo("Failed to create pull request")
        return 1


def cmd_merge(config: Config) -> int:
    """Merge an existing pull request."""
    cmd = ["gh", "pr", "merge", f"--{config.strategy}"]
    if config.admin:
        cmd.append("--admin")

    result = run_cmd(cmd, capture=True)
    if result.returncode == 0:
        click.echo("Pull request merged successfully!")
        open_pr_in_browser("files")
        return 0
    else:
        click.echo("Failed to merge pull request:")
        click.echo(result.stderr or result.stdout)
        return 1


def cmd_view() -> int:
    """View pull request files in browser."""
    click.echo("Opening pull request in browser...")
    open_pr_in_browser("files")
    return 0


@click.group()
def cli():
    """GitHub PR management tool."""


@cli.command()
@click.option(
    "--assignee",
    default="@me",
    show_default=True,
    help="Specify the assignee for the pull request",
)
@click.option(
    "--reviewers", default="", help="Specify the reviewers for the pull request"
)
@click.option("--labels", default="", help="Specify the label for the pull request")
@click.option(
    "--update",
    type=click.Choice(["rebase", "merge"]),
    default="rebase",
    show_default=True,
    help="Specify the update strategy",
)
@click.option("--draft", is_flag=True, help="Create a draft pull request")
def create(assignee, reviewers, labels, update, draft):
    """Create a new pull request."""
    if not check_git_repo():
        raise click.ClickException("Not in a git repository")
    current_branch = get_current_branch()
    if current_branch in ("main", "master"):
        raise click.ClickException(
            f"You are on the {current_branch} branch. "
            "This script cannot be run on main or master branches."
        )
    unset_github_tokens()

    config = Config(
        assignee=assignee,
        reviewer=reviewers or "",
        label=labels or "",
        update=update,
        draft=draft,
    )
    sys.exit(cmd_create(config))


@cli.command()
@click.option(
    "--strategy",
    type=click.Choice(["squash", "merge", "rebase"]),
    default="squash",
    show_default=True,
    help="Specify the merge strategy",
)
@click.option(
    "--admin",
    "--bypass",
    "admin",
    is_flag=True,
    help="Use administrator privileges to bypass merge queue requirements",
)
def merge(strategy, admin):
    """Merge an existing pull request."""
    if not check_git_repo():
        raise click.ClickException("Not in a git repository")
    current_branch = get_current_branch()
    if current_branch in ("main", "master"):
        raise click.ClickException(
            f"You are on the {current_branch} branch. "
            "This script cannot be run on main or master branches."
        )
    unset_github_tokens()

    config = Config(strategy=strategy, admin=admin)
    sys.exit(cmd_merge(config))


@cli.command()
def view():
    """View pull request files in browser."""
    if not check_git_repo():
        raise click.ClickException("Not in a git repository")
    current_branch = get_current_branch()
    if current_branch in ("main", "master"):
        raise click.ClickException(
            f"You are on the {current_branch} branch. "
            "This script cannot be run on main or master branches."
        )
    unset_github_tokens()

    sys.exit(cmd_view())


def main() -> int:
    cli(standalone_mode=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
