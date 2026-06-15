"""Scope/title formatting for git-commit-scope."""

import re

import click

MACHINE_MAPPINGS = {
    "Ivans-Mac-mini": "mini",
    "Ivans-MacBook-Air": "air",
    "Ivans-MacBook-Pro": "pro",
    "Lusha-Macbook-Ivan-Kovnatskyi": "work",
}

DIRECTORY_MAPPINGS = {
    "packages": "pkg",
    "modules": "mod",
    "overlays": "ovl",
    "machines": "m",
    "darwin": "drw",
    "server": "srv",
    "service": "svc",
    "home": "hm",
    "nixvim": "nvim",
}

MAX_MESSAGE_LENGTH = 72
MIN_SCOPE_SEGMENTS = 2


def shorten_path(path: str) -> str:
    result = path

    # Strip file extension (requires word char before dot, e.g., file.py but not .gitconfig)
    result = re.sub(r"(?<=\w)\.[a-zA-Z0-9]+$", "", result)

    # Shorten machine names
    for long_name, short_name in MACHINE_MAPPINGS.items():
        result = result.replace(long_name, short_name)

    # Remove duplicate path component (e.g., packages/git-commit-scope/git-commit-scope -> packages/git-commit-scope)
    parts = result.split("/")
    if len(parts) >= 2 and parts[-1] == parts[-2]:
        result = "/".join(parts[:-1])

    # Strip "default" filename (default.nix is conventional entry point)
    parts = result.split("/")
    if len(parts) >= 2 and parts[-1] == "default":
        result = "/".join(parts[:-1])

    return result


def shorten_directories(path: str) -> str:
    """Apply aggressive directory shortening (packages->pkg, modules->mod, etc.)."""
    parts = path.split("/")
    shortened = [DIRECTORY_MAPPINGS.get(p, p) for p in parts]
    return "/".join(shortened)


def collapse_middle_segments(
    path: str, subject: str, max_length: int = MAX_MESSAGE_LENGTH
) -> str:
    """Collapse interior path segments into a single '*' to fit the message.

    Unlike compress_path (which drops rightmost segments and loses the
    filename), this keeps both the leading category and the trailing filename
    context, replacing the noisy middle with '*'.

    e.g. Settings/Learning/HarvardCS50... -> Settings/*/HarvardCS50...

    Tries to preserve as many leading segments as possible: collapses the
    smallest interior run first, widening it until the message fits. Returns
    the original path unchanged if it has no collapsible middle (< 3 segments)
    or if no collapse makes it fit.
    """
    parts = path.split("/")
    if len(parts) < 3:
        return path

    original = path
    last = parts[-1]
    # Keep p0..parts[i] then '*' then last; i shrinks to collapse more middle.
    # Start at len-3 so '*' always replaces at least one interior segment.
    for i in range(len(parts) - 3, 0, -1):
        head = parts[: i + 1]
        candidate = "/".join(head + ["*", last])
        if len(f"{candidate}: {subject}") <= max_length:
            click.echo(
                f"  scope: {original} → {candidate} (collapsed middle)",
                err=True,
            )
            return candidate

    candidate = "/".join([parts[0], "*", last])
    if len(f"{candidate}: {subject}") <= max_length:
        click.echo(
            f"  scope: {original} → {candidate} (collapsed middle)",
            err=True,
        )
        return candidate

    return path


def compress_path(path: str, subject: str, max_length: int = MAX_MESSAGE_LENGTH) -> str:
    """Progressively drop rightmost path segments until scope: subject fits.

    Stops at MIN_SCOPE_SEGMENTS to avoid overly vague scopes.
    """
    parts = path.split("/")
    if len(parts) <= MIN_SCOPE_SEGMENTS:
        return path

    original = path
    while len(parts) > MIN_SCOPE_SEGMENTS:
        candidate = "/".join(parts)
        if len(f"{candidate}: {subject}") <= max_length:
            if candidate != original:
                dropped = len(original.split("/")) - len(parts)
                click.echo(
                    f"  scope: {original} → {candidate} (dropped {dropped} segments)",
                    err=True,
                )
            return candidate
        parts = parts[:-1]

    # At minimum depth
    candidate = "/".join(parts)
    if candidate != original:
        dropped = len(original.split("/")) - len(parts)
        click.echo(
            f"  scope: {original} → {candidate} (dropped {dropped} segments)",
            err=True,
        )
    return candidate


def create_commit_message(prefix: str, subject: str) -> str:
    return f"{prefix}: {subject}"


def validate_title(title: str) -> list[str]:
    """Collect all hook-equivalent violations for a commit title.

    Mirrors the global commit-msg hook (home/git/default.nix) so failures
    surface up-front from the CLI instead of one-at-a-time from the hook.
    """
    errors = []
    if len(title) > MAX_MESSAGE_LENGTH:
        errors.append(
            f"Commit title must be ≤{MAX_MESSAGE_LENGTH} characters (got {len(title)})"
        )
    scope = title.split(": ", 1)[0] if ": " in title else ""
    if "," in scope:
        errors.append(
            "Commas not allowed in commit scope "
            "(split into separate commits or use a general subject)"
        )
    if ";" in title:
        errors.append("Semicolons not allowed in commit title")
    return errors


def create_rename_message(old_path: str, new_path: str) -> str:
    """Create a commit message for a rename using arrow notation."""
    old_scope = shorten_path(old_path)
    new_scope = shorten_path(new_path)
    msg = f"{old_scope} -> {new_scope}"
    if len(msg) > MAX_MESSAGE_LENGTH:
        old_scope = shorten_directories(old_scope)
        new_scope = shorten_directories(new_scope)
        msg = f"{old_scope} -> {new_scope}"
    return msg


def changes_are_only_renames(
    all_files: list[str], renames: list[tuple[str, str]]
) -> bool:
    """Check if all changed files are accounted for by renames."""
    if not renames:
        return False
    rename_paths = set()
    for old, new in renames:
        rename_paths.add(old)
        rename_paths.add(new)
    return all(f in rename_paths for f in all_files)
