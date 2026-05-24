#!/usr/bin/env python3
"""Nix rebuild tool with two modes:
rebuild CONFIG_PATH         - single rebuild with notifications (quiet output)
rebuild watch CONFIG_PATH   - watchman file-watching + optional loop/polling
"""

import logging
import sys

from cli import cli


# Configure logging to write to stdout instead of stderr
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout)],
)


if __name__ == "__main__":
    cli(prog_name="rebuild")
