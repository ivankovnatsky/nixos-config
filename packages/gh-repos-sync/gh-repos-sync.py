#!/usr/bin/env python3
"""Diff GitHub repos vs local clones; clone only what is missing.

Safe by design: never deletes, never modifies existing repos.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import click


def die(msg: str, code: int = 1) -> None:
    click.echo(msg, err=True)
    sys.exit(code)


def run(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, check=check, capture_output=True, text=True)


def preflight() -> None:
    for tool in ("gh", "git"):
        if shutil.which(tool) is None:
            die(f"{tool} not found")
    try:
        subprocess.run(
            ["gh", "auth", "status"],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        die("gh not authenticated")


REPO_LIMIT = 10000


def remote_repos(user: str) -> list[str]:
    try:
        res = run([
            "gh", "repo", "list", user,
            "--limit", str(REPO_LIMIT),
            "--source",
            "--no-archived",
            "--json", "name,isFork",
        ])
    except subprocess.CalledProcessError as exc:
        die(f"gh repo list failed: {exc.stderr.strip() or exc}")
    try:
        data = json.loads(res.stdout)
    except json.JSONDecodeError as exc:
        die(f"could not parse gh output: {exc}")
    if len(data) >= REPO_LIMIT:
        die(
            f"hit repo limit ({REPO_LIMIT}); raise REPO_LIMIT in the script "
            "or paginate via 'gh api graphql --paginate'."
        )
    return sorted(r["name"] for r in data if not r["isFork"])


def origin_matches(origin: str, user: str, repo: str) -> bool:
    normalized = origin.strip().rstrip("/")
    if normalized.endswith(".git"):
        normalized = normalized[:-4]
    expected = {
        f"https://github.com/{user}/{repo}",
        f"http://github.com/{user}/{repo}",
        f"git@github.com:{user}/{repo}",
        f"ssh://git@github.com/{user}/{repo}",
    }
    return normalized in expected


def path_present(p: Path) -> bool:
    """True if a file/dir/symlink exists at p (including broken symlinks)."""
    return p.exists() or p.is_symlink()


def origin_of(repo_dir: Path) -> str | None:
    git_marker = repo_dir / ".git"
    if not git_marker.exists():
        return None
    try:
        res = subprocess.run(
            [
                "git", "-C", str(repo_dir),
                "config", "--get", "remote.origin.url",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError:
        return None
    return res.stdout.strip() or None


def section(title: str, items: list[str]) -> None:
    if not items:
        return
    click.echo(f"== {title}: {len(items)} ==")
    for item in items:
        click.echo(item)
    click.echo()


@click.command(
    help=(
        "Lists NEW (missing) / EXISTING (origin verified) / "
        "COLLISION (same name, different origin) / LOCAL-ONLY repos. "
        "Without --dry-run, clones NEW via 'git clone'. "
        "Never deletes or modifies existing repos."
    ),
)
@click.argument("user")
@click.option(
    "-p", "--path", "path_",
    default=None,
    type=click.Path(file_okay=False, dir_okay=True, resolve_path=True),
    help="Directory containing local clones (default: current dir).",
)
@click.option(
    "-n", "--dry-run", is_flag=True,
    help="List only; do not clone.",
)
@click.option(
    "--protocol",
    type=click.Choice(["https", "ssh"]),
    default="https",
    show_default=True,
    help="Clone URL scheme.",
)
def main(
    user: str, path_: str | None, dry_run: bool, protocol: str,
) -> None:
    base = Path(path_ or os.getcwd()).resolve()
    if not base.is_dir():
        die(f"not a directory: {base}")

    preflight()
    remote = remote_repos(user)
    remote_set = set(remote)

    new: list[str] = []
    existing: list[str] = []
    collision: list[str] = []

    for repo in remote:
        target = base / repo
        if not path_present(target):
            new.append(repo)
            continue
        origin = origin_of(target)
        if origin and origin_matches(origin, user, repo):
            existing.append(repo)
        else:
            collision.append(f"{repo} (origin: {origin or '<none>'})")

    local_dirs = sorted(
        p.name
        for p in base.iterdir()
        if p.is_dir() and not p.name.startswith(".")
    )
    orphan = [d for d in local_dirs if d not in remote_set]

    section("NEW (would clone)", new)
    section("COLLISION (skipped, manual review)", collision)
    section("LOCAL-ONLY (not on remote / fork / archived)", orphan)

    if not (new or collision or orphan):
        click.echo(f"all clean ({len(existing)} repos in sync)")
        return

    if dry_run:
        return
    if not new:
        return

    failures: list[str] = []
    clone_env = {**os.environ, "GIT_TERMINAL_PROMPT": "0"}
    for repo in new:
        target = base / repo
        try:
            os.mkdir(target)
        except FileExistsError:
            click.echo(f"skip {repo}: target exists (race)", err=True)
            continue
        url = (
            f"git@github.com:{user}/{repo}.git"
            if protocol == "ssh"
            else f"https://github.com/{user}/{repo}.git"
        )
        click.echo(f"cloning {repo}")
        try:
            subprocess.run(
                ["git", "clone", url, str(target)],
                check=True,
                env=clone_env,
            )
        except subprocess.CalledProcessError as exc:
            # Remove the partial clone so the next run retries cleanly.
            # target was just created by os.mkdir above; only contents
            # are whatever git wrote during this failed clone.
            if not target.is_symlink() and target.is_dir():
                shutil.rmtree(target, ignore_errors=True)
            click.echo(
                f"clone failed for {repo}: exit {exc.returncode}",
                err=True,
            )
            failures.append(repo)

    if failures:
        die(f"{len(failures)} clone(s) failed: {', '.join(failures)}")


if __name__ == "__main__":
    main()
