#!/usr/bin/env python3
"""Manage the GPG passphrase cache."""

import subprocess
import sys

import click

DEFAULT_KEY = "75213+ivankovnatsky@users.noreply.github.com"


def run(command: list[str]) -> None:
    result = subprocess.run(command)
    if result.returncode != 0:
        sys.exit(result.returncode)


def cache_passphrase() -> None:
    run(
        [
            "gpg",
            "--sign",
            "--default-key",
            DEFAULT_KEY,
            "-o",
            "/dev/null",
            "/dev/null",
        ]
    )
    click.echo("GPG passphrase cached.")


@click.group()
def main() -> None:
    """Manage the GPG passphrase cache."""


@main.command()
def cache() -> None:
    """Cache the configured GPG key passphrase."""
    cache_passphrase()


@main.command()
def drop() -> None:
    """Drop the cached GPG passphrase."""
    run(["gpgconf", "--kill", "gpg-agent"])
    click.echo("GPG passphrase cache dropped.")


if __name__ == "__main__":
    main(prog_name="gpg-pass")
