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
            with open(custom_config, 'r') as f:
                config = json.load(f)
                patterns.extend(config.get('ignore_patterns', []))
        except Exception as e:
            logging.warning(f"Failed to parse .watchman-rebuild.json: {e}")

    return patterns


def build_watchman_expression(ignore_patterns):
    """Build watchman expression with exclusions from ignore patterns."""
    expression = ['allof', ['type', 'f']]

    for pattern in ignore_patterns:
        if '*' in pattern:
            # Pattern with wildcard - match against file basename
            expression.append(['not', ['match', pattern, 'basename']])
        else:
            # Directory name - exclude entire directory
            expression.append(['not', ['dirname', pattern]])

    return expression
