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


def get_machine_dirs(config_path):
    """Return set of machine directory names under machines/."""
    machines_dir = Path(config_path) / "machines"
    if machines_dir.is_dir():
        return {d.name for d in machines_dir.iterdir() if d.is_dir()}
    return set()


def filter_files_for_machine(files, other_machines):
    """Filter out files belonging to other machines.

    Files under machines/<other-hostname>/ are excluded.
    All other paths are kept.
    """
    if not other_machines:
        return files

    relevant = []
    skipped = []
    for f in files:
        parts = Path(f).parts
        # Check if file is under machines/<other>/
        if len(parts) >= 2 and parts[0] == "machines" and parts[1] in other_machines:
            skipped.append(f)
        else:
            relevant.append(f)

    if skipped:
        logging.info(
            f"Filtered out {len(skipped)} file(s) belonging to other machines"
        )
        for f in skipped[:5]:
            logging.debug(f"  skipped: {f}")
        if len(skipped) > 5:
            logging.debug(f"  ... and {len(skipped) - 5} more")

    return relevant
