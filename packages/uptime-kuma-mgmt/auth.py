"""Authentication helpers for uptime-kuma-mgmt."""

import os
import sys

from constants import (
    ENV_BASE_URL,
    ENV_USERNAME,
    ENV_PASSWORD,
    DEFAULT_USERNAME_PATH,
    DEFAULT_PASSWORD_PATH,
)


def read_secret(env_var: str, default_path: str) -> str | None:
    """Read secret from env var or default file path."""
    if value := os.environ.get(env_var):
        return value

    try:
        return open(os.path.expanduser(default_path)).read().strip()
    except (OSError, IOError):
        return None


def add_auth_args(subparser):
    """Add common authentication arguments to a subparser."""
    subparser.add_argument(
        "--base-url",
        default=os.environ.get(ENV_BASE_URL),
        help=f"Uptime Kuma base URL (or set {ENV_BASE_URL})",
    )
    subparser.add_argument(
        "--username",
        default=read_secret(ENV_USERNAME, DEFAULT_USERNAME_PATH),
        help=f"Username (or set {ENV_USERNAME}, default: {DEFAULT_USERNAME_PATH})",
    )
    subparser.add_argument(
        "--password",
        default=read_secret(ENV_PASSWORD, DEFAULT_PASSWORD_PATH),
        help=f"Password (or set {ENV_PASSWORD}, default: {DEFAULT_PASSWORD_PATH})",
    )


def validate_auth_args(args):
    """Validate that all required auth arguments are provided."""
    missing = []
    if not args.base_url:
        missing.append(f"--base-url or {ENV_BASE_URL}")
    if not args.username:
        missing.append(f"--username or {ENV_USERNAME}")
    if not args.password:
        missing.append(f"--password or {ENV_PASSWORD}")
    if missing:
        print(
            f"Error: Missing required arguments: {', '.join(missing)}", file=sys.stderr
        )
        sys.exit(1)
