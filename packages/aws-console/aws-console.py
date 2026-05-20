#!/usr/bin/env python3

"""Open an AWS SSO console for a profile in the default browser.

Reads ~/.aws/config for SSO profiles (anything whose credential_process line
contains an iam::<acct>:role/<role> ARN) and ~/.aws-sso/config.yaml for the
SSO portal start URL (AWS_SSO_START_URL env var overrides).

With no flags it shows an fzf picker. --account / --role narrow the candidates;
when they leave exactly one match the picker is skipped (non-interactive use).
"""

import configparser
import os
import re
import subprocess
import sys
import urllib.parse
from pathlib import Path

import click

AWS_CONFIG = Path.home() / ".aws" / "config"
AWS_SSO_CONFIG = Path.home() / ".aws-sso" / "config.yaml"
ARN_RE = re.compile(r"arn:aws:iam::(\d+):role/(\S+)")
START_URL_RE = re.compile(r"^\s*StartUrl:\s*(\S+)", re.MULTILINE)


def load_start_url() -> str:
    env = os.environ.get("AWS_SSO_START_URL")
    if env:
        return env
    if AWS_SSO_CONFIG.is_file():
        m = START_URL_RE.search(AWS_SSO_CONFIG.read_text())
        if m:
            return m.group(1)
    raise click.ClickException(
        f"SSO start URL not found. Set AWS_SSO_START_URL or populate {AWS_SSO_CONFIG}"
    )


def load_profiles() -> list[tuple[str, str, str]]:
    if not AWS_CONFIG.is_file():
        raise click.ClickException(f"{AWS_CONFIG} not found")

    parser = configparser.RawConfigParser()
    parser.read(AWS_CONFIG)

    entries: list[tuple[str, str, str]] = []
    for section in parser.sections():
        if not section.startswith("profile "):
            continue
        name = section[len("profile ") :]
        cred = parser[section].get("credential_process", "")
        m = ARN_RE.search(cred)
        if not m:
            continue
        entries.append((name, m.group(1), m.group(2)))
    return entries


def pick(entries: list[tuple[str, str, str]]) -> tuple[str, str, str]:
    width = max(len(e[0]) for e in entries)
    lines = [f"{name:<{width}}  {acct}  {role}" for name, acct, role in entries]
    fzf = subprocess.run(
        ["fzf", "--height=60%", "--border", "--prompt=AWS account > "],
        input="\n".join(lines),
        text=True,
        capture_output=True,
    )
    if fzf.returncode in (1, 130):
        sys.exit(fzf.returncode)
    if fzf.returncode != 0:
        raise click.ClickException(f"fzf failed: {fzf.stderr.strip()}")
    idx = lines.index(fzf.stdout.rstrip("\n"))
    return entries[idx]


def match(
    entries: list[tuple[str, str, str]], account: str | None, role: str | None
) -> list[tuple[str, str, str]]:
    """Filter entries by account (name or id) and role, case-insensitively."""
    out = entries
    if account:
        needle = account.lower()
        out = [e for e in out if needle in e[0].lower() or needle == e[1]]
    if role:
        needle = role.lower()
        out = [e for e in out if needle == e[2].lower()]
    return out


@click.command()
@click.option(
    "-a", "--account", help="Account name (substring) or 12-digit account id."
)
@click.option("-r", "--role", help="Exact SSO role name.")
@click.option(
    "-p", "--print", "print_url", is_flag=True, help="Print the URL instead of opening it."
)
def main(account: str | None, role: str | None, print_url: bool) -> None:
    """Open the AWS SSO console for a selected profile."""
    start_url = load_start_url()
    entries = load_profiles()
    if not entries:
        raise click.ClickException(f"no SSO role profiles found in {AWS_CONFIG}")

    candidates = match(entries, account, role)
    if not candidates:
        raise click.ClickException(
            f"no profile matches account={account!r} role={role!r}"
        )
    if len(candidates) == 1:
        _, account_id, role_name = candidates[0]
    else:
        _, account_id, role_name = pick(candidates)

    qs = urllib.parse.urlencode({"account_id": account_id, "role_name": role_name})
    url = f"{start_url.rstrip('/')}/#/console?{qs}"
    if print_url:
        click.echo(url)
    else:
        subprocess.run(["open", url], check=True)


if __name__ == "__main__":
    main()
