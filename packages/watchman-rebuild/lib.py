"""
Shared watchman functionality that reads config from .watchman-rebuild.json.
"""

import json
import logging
from pathlib import Path


def load_watchman_ignores(config_path):
    """Load ignore patterns from .watchman-rebuild.json."""
    patterns = []

    # Load our custom patterns from .watchman-rebuild.json
    custom_config = Path(config_path) / ".watchman-rebuild.json"
    if custom_config.exists():
        try:
            with open(custom_config, "r") as f:
                config = json.load(f)
                raw_patterns = config.get("ignore_patterns", [])
                # Strip trailing slashes to ensure consistent matching
                patterns.extend([p.rstrip("/") for p in raw_patterns])
        except Exception as e:
            logging.warning(f"Failed to parse .watchman-rebuild.json: {e}")

    return patterns


def build_watchman_expression(ignore_patterns):
    """Build watchman expression with exclusions from ignore patterns."""
    expression = ["allof", ["type", "f"]]

    for pattern in ignore_patterns:
        # Match options to ensure we catch hidden files/directories
        match_opts = {"includedotfiles": True}

        if "*" in pattern:
            # Wildcard pattern - match against wholename (recursive)
            # If it doesn't start with **, try both absolute and relative-to-any-dir
            expression.append(["not", ["match", pattern, "wholename", match_opts]])
            if not pattern.startswith("**"):
                expression.append(
                    ["not", ["match", f"**/{pattern}", "wholename", match_opts]]
                )
        else:
            # Simple name - treat as directory (recursive) or exact file match
            # 1. Match as a directory anywhere in the tree
            expression.append(
                ["not", ["match", f"**/{pattern}/**", "wholename", match_opts]]
            )
            # 2. Match as a directory at the root
            expression.append(
                ["not", ["match", f"{pattern}/**", "wholename", match_opts]]
            )
            # 3. Match as a filename anywhere in the tree
            expression.append(
                ["not", ["match", f"**/{pattern}", "wholename", match_opts]]
            )
            # 4. Match as a filename at the root or exact basename
            expression.append(["not", ["match", pattern, "wholename", match_opts]])
            expression.append(["not", ["match", pattern, "basename", match_opts]])

    return expression
