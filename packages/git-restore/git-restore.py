#!/usr/bin/env python3
"""Unstage and restore file(s) to HEAD in a single command."""

import subprocess
import sys

import click


@click.command()
@click.argument("files", nargs=-1, required=True)
def main(files) -> None:
    """Unstage and restore file(s) to HEAD (git restore --staged --worktree)."""
    result = subprocess.run(
        ["git", "restore", "--staged", "--worktree", "--", *files],
    )
    sys.exit(result.returncode)


if __name__ == "__main__":
    main(prog_name="git-restore")
