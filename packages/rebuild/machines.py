"""Hostname → nix-config path mapping.

Used by the CLI to resolve a config path when the user invokes `rebuild`
without an explicit argument, regardless of the current working directory.
Paths may contain `~` which is expanded at lookup time.
"""

import os
import socket


# Default for every host except those listed in OVERRIDES below.
DEFAULT_PATH = "~/Sources/github.com/ivankovnatsky/nix-config"

# Hosts whose nix-config does not live under $HOME/Sources.
OVERRIDES = {}


def current_hostname():
    return socket.gethostname().removesuffix(".local")


def resolve_config_path():
    """Return nix-config path for the current host."""
    path = OVERRIDES.get(current_hostname(), DEFAULT_PATH)
    return os.path.expanduser(path)
