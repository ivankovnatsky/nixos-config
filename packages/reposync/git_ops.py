"""Git subprocess helpers."""

import os
import subprocess

import click

GIT_TIMEOUT = 60 * 5


def run_git(*args, cwd=None, check=True, timeout=GIT_TIMEOUT):
    try:
        result = subprocess.run(
            ["git"] + list(args),
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(
            args, 1, "", f"git {args[0]} timed out after {timeout}s"
        )
    if check and result.returncode != 0:
        click.echo(f"Error: {result.stderr.strip()}", err=True)
    return result


def has_git_lock(path):
    git_dir = os.path.join(path, ".git")
    for lock in ("index.lock", "HEAD.lock", "config.lock"):
        if os.path.exists(os.path.join(git_dir, lock)):
            return True
    return False
