#!/usr/bin/env python3
"""
Vault Authentication Script

Handles Vault authentication using OIDC method and stores the token
securely using the 'pass' password manager.

Usage:
    eval $(vault-auth --address "https://vault.example.com" \
                      --username "user@example.com" \
                      --path "custom_oidc" \
                      --role "custom_role")
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile


def log(msg: str) -> None:
    """Print message to stderr."""
    print(msg, file=sys.stderr)


def run_cmd(cmd: list[str], capture: bool = True, env: dict | None = None) -> tuple[int, str]:
    """Run a command and return (returncode, stdout)."""
    merged_env = {**os.environ, **(env or {})}
    result = subprocess.run(
        cmd,
        capture_output=capture,
        text=True,
        env=merged_env,
    )
    return result.returncode, result.stdout.strip() if capture else ""


def check_pass_available() -> bool:
    """Check if pass command is available."""
    return shutil.which("pass") is not None


def fetch_token_from_pass(vault_addr: str, user_email: str) -> str | None:
    """Fetch token from pass password store."""
    if not check_pass_available():
        log("Warning: 'pass' command not found. Cannot retrieve stored token.")
        return None

    pass_path = f"{vault_addr.removeprefix('https://')}/{user_email}/token"
    returncode, token = run_cmd(["pass", pass_path])
    return token if returncode == 0 and token else None


def is_token_valid(vault_addr: str, token: str) -> bool:
    """Check if the vault token is valid."""
    if not token:
        return False

    returncode, _ = run_cmd(
        ["vault", "token", "lookup"],
        env={"VAULT_ADDR": vault_addr, "VAULT_TOKEN": token},
    )
    return returncode == 0


def update_token_in_pass(vault_addr: str, user_email: str, token: str) -> bool:
    """Update token in pass password store."""
    if not token:
        log("Error: Cannot store empty token.")
        return False

    if not check_pass_available():
        log("Warning: 'pass' command not found. Cannot store token.")
        return False

    pass_path = f"{vault_addr.removeprefix('https://')}/{user_email}/token"
    log(f"Updating {pass_path}...")

    process = subprocess.run(
        ["pass", "insert", "--echo", "--force", pass_path],
        input=token,
        text=True,
        capture_output=True,
    )
    return process.returncode == 0


def patch_envrc_secrets(token: str) -> bool:
    """Patch VAULT_TOKEN in envrc/secrets (preserves other secrets)."""
    envrc_path = "envrc/secrets"

    if not token:
        log("Error: Cannot patch with empty token.")
        return False

    if not check_pass_available():
        log("Warning: 'pass' command not found. Cannot patch envrc/secrets.")
        return False

    # Check if envrc/secrets exists
    returncode, _ = run_cmd(["pass", "show", envrc_path])
    if returncode != 0:
        log(f"Warning: {envrc_path} not found in pass. Skipping patch.")
        return True

    # Read current contents
    returncode, current_contents = run_cmd(["pass", "show", envrc_path])
    if returncode != 0:
        log(f"Error: Failed to read {envrc_path}")
        return False

    lines = current_contents.split("\n")

    # Check if token is already up to date
    vault_token_pattern = re.compile(r"^export VAULT_TOKEN=(.*)$")
    current_token = None
    token_line_idx = None

    for idx, line in enumerate(lines):
        match = vault_token_pattern.match(line)
        if match:
            current_token = match.group(1)
            token_line_idx = idx
            break

    if current_token == token:
        log("envrc/secrets already up to date")
        return True

    # Update or add token
    new_token_line = f"export VAULT_TOKEN={token}"

    if token_line_idx is not None:
        log("Updating VAULT_TOKEN in envrc/secrets...")
        lines[token_line_idx] = new_token_line
    else:
        log("Adding VAULT_TOKEN to envrc/secrets...")
        lines.append(new_token_line)

    new_contents = "\n".join(lines)

    # Write back to pass using temp file for safety
    with tempfile.NamedTemporaryFile(mode="w", delete=False) as tmp:
        tmp.write(new_contents)
        tmp_path = tmp.name

    try:
        os.chmod(tmp_path, 0o600)
        with open(tmp_path) as f:
            process = subprocess.run(
                ["pass", "insert", "--multiline", "--force", envrc_path],
                stdin=f,
                capture_output=True,
            )
        return process.returncode == 0
    finally:
        os.unlink(tmp_path)


def vault_login(vault_addr: str, oidc_path: str, role: str) -> str | None:
    """Login to vault using OIDC and return token."""
    returncode, token = run_cmd(
        [
            "vault",
            "login",
            "-method=oidc",
            f"-path={oidc_path}",
            "-token-only",
            f"role={role}",
        ],
        env={"VAULT_ADDR": vault_addr},
    )
    return token if returncode == 0 and token else None


def output_exports(vault_addr: str, token: str) -> None:
    """Output shell export statements."""
    # Check if running in fish shell
    fish_version = os.environ.get("FISH_VERSION")
    shell = os.environ.get("SHELL", "")

    if fish_version or "fish" in shell:
        # Fish shell syntax
        print(f'set -gx VAULT_ADDR "{vault_addr}";')
        print(f'set -gx VAULT_TOKEN "{token}";')
    else:
        # Bash/zsh syntax
        print(f'export VAULT_ADDR="{vault_addr}"')
        print(f'export VAULT_TOKEN="{token}"')


def main() -> int:
    parser = argparse.ArgumentParser(description="Vault OIDC Authentication")
    parser.add_argument(
        "--address",
        "-a",
        required=True,
        help="Vault server URL",
    )
    parser.add_argument(
        "--username",
        "-u",
        required=True,
        help="User email for authentication",
    )
    parser.add_argument(
        "--path",
        "-p",
        required=True,
        help="OIDC authentication path",
    )
    parser.add_argument(
        "--role",
        "-r",
        required=True,
        help="Vault role to use",
    )

    args = parser.parse_args()

    vault_addr = args.address
    user_email = args.username
    oidc_path = args.path
    role = args.role

    # Try to fetch token from pass
    token = fetch_token_from_pass(vault_addr, user_email)

    # If token is not in pass or expired, login to get a new one
    if not token or not is_token_valid(vault_addr, token):
        log("Fetching new token from Vault login...")

        token = vault_login(vault_addr, oidc_path, role)

        if token:
            log("Token fetched successfully")
            update_token_in_pass(vault_addr, user_email, token)
            patch_envrc_secrets(token)
        else:
            log("Failed to fetch token from Vault")
            return 1
    else:
        log("Using existing valid token")
        # Sync envrc/secrets in case it's out of date
        patch_envrc_secrets(token)

    output_exports(vault_addr, token)
    return 0


if __name__ == "__main__":
    sys.exit(main())
