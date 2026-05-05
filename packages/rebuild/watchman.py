"""Watchman subscription helpers and machine-aware file filtering."""

import json
import logging
from pathlib import Path


def load_watchman_ignores(config_path):
    """Load ignore patterns from .rebuild.json."""
    patterns = []
    custom_config = Path(config_path) / ".rebuild.json"
    if custom_config.exists():
        try:
            with open(custom_config, "r") as f:
                config = json.load(f)
                raw_patterns = config.get("ignore_patterns", [])
                patterns.extend([p.rstrip("/") for p in raw_patterns])
        except Exception as e:
            logging.warning(f"Failed to parse .rebuild.json: {e}")
    return patterns


def build_watchman_expression(ignore_patterns):
    """Build watchman expression with exclusions from ignore patterns."""
    expression = ["allof", ["type", "f"]]

    for pattern in ignore_patterns:
        match_opts = {"includedotfiles": True}

        if "*" in pattern:
            expression.append(["not", ["match", pattern, "wholename", match_opts]])
            if not pattern.startswith("**"):
                expression.append(
                    ["not", ["match", f"**/{pattern}", "wholename", match_opts]]
                )
        else:
            expression.append(
                ["not", ["match", f"**/{pattern}/**", "wholename", match_opts]]
            )
            expression.append(
                ["not", ["match", f"{pattern}/**", "wholename", match_opts]]
            )
            expression.append(
                ["not", ["match", f"**/{pattern}", "wholename", match_opts]]
            )
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
    """Filter out files belonging to other machines."""
    if not other_machines:
        return files

    relevant = []
    skipped = []
    for f in files:
        parts = Path(f).parts
        if len(parts) >= 2 and parts[0] == "machines" and parts[1] in other_machines:
            skipped.append(f)
        else:
            relevant.append(f)

    if skipped:
        logging.info(f"Filtered out {len(skipped)} file(s) belonging to other machines")
        for f in skipped[:5]:
            logging.debug(f"  skipped: {f}")
        if len(skipped) > 5:
            logging.debug(f"  ... and {len(skipped) - 5} more")

    return relevant


def setup_watchman_subscription(client, config_path, ignore_patterns):
    """Set up watchman watch and subscription."""
    watch_result = client.query("watch-project", config_path)
    if "warning" in watch_result:
        logging.warning(f"Watchman warning: {watch_result['warning']}")

    root = watch_result["watch"]
    relative_path = watch_result.get("relative_path", "")

    logging.info(f"Watchman watching: {root}")

    query = {
        "expression": build_watchman_expression(ignore_patterns),
        "fields": ["name"],
    }

    if relative_path:
        query["relative_root"] = relative_path

    sub_name = "rebuild"
    client.query("subscribe", root, sub_name, query)

    logging.info("Watching for changes...")
    return root, sub_name
