#!/usr/bin/env python3
"""Report .nix files that no module imports (orphans).

Builds the import graph by following literal relative-path references
(`./foo.nix`, `../../home/bar.nix`, `./somedir`) from a set of entry points
and flags every .nix file that is never reached.

Entry points that Nix loads without a literal path reference are seeded as
roots: the flake itself, and every packages/*/ and overlays/*/ directory
(auto-discovered via builtins.readDir in flake/overlay.nix).

Runs as a treefmt formatter: treefmt passes the matching .nix files as
arguments, which are used only to locate the repository root. The whole tree
is always scanned regardless of which files were passed, so treefmt's
per-file caching cannot hide an orphan. The check reports only — it never
edits files — and exits non-zero when orphans exist so treefmt surfaces them.
"""

import os
import re
import sys
import click
from pathlib import Path

# Matches a Nix relative path literal: starts with ./ or ../, runs until a
# character that can't be part of a path token.
PATH_RE = re.compile(r"\.\.?/[A-Za-z0-9_./+-]+")


def find_root(start: Path):
    """Walk up from a file or directory until a flake.nix is found."""
    cur = start if start.is_dir() else start.parent
    for candidate in [cur, *cur.parents]:
        if (candidate / "flake.nix").is_file():
            return candidate
    return None


def resolve(ref: str, from_dir: Path):
    """Resolve a relative reference to a concrete .nix file, or None."""
    target = (from_dir / ref).resolve()
    if target.is_file() and target.suffix == ".nix":
        return target
    if target.is_dir():
        default = target / "default.nix"
        if default.is_file():
            return default
    # Bare reference without extension pointing at a single file.
    with_nix = target.with_suffix(".nix")
    if with_nix.is_file():
        return with_nix
    return None


def refs_in(path: Path):
    try:
        text = path.read_text()
    except (UnicodeDecodeError, OSError):
        return []
    return PATH_RE.findall(text)


def collect_roots(root: Path):
    roots = set()
    flake = root / "flake.nix"
    if flake.is_file():
        roots.add(flake)
    for auto in ("packages", "overlays"):
        base = root / auto
        if not base.is_dir():
            continue
        for entry in base.iterdir():
            default = entry / "default.nix"
            if default.is_file():
                roots.add(default.resolve())
    return roots


def all_nix_files(root: Path):
    files = set()
    for dirpath, dirnames, filenames in os.walk(root):
        if ".git" in dirnames:
            dirnames.remove(".git")
        for name in filenames:
            if name.endswith(".nix"):
                files.add((Path(dirpath) / name).resolve())
    return files


def reachable_from(roots):
    seen = set()
    stack = list(roots)
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for ref in refs_in(cur):
            resolved = resolve(ref, cur.parent)
            if resolved and resolved not in seen:
                stack.append(resolved)
    return seen


@click.command()
@click.argument("files", nargs=-1, type=click.Path(exists=True))
@click.option(
    "--root",
    type=click.Path(exists=True, file_okay=False),
    default=None,
    help="Repository root (default: derived from FILES, else cwd).",
)
def main(files, root):
    """List .nix files not reachable from any entry point."""
    if root is not None:
        root = Path(root).resolve()
    elif files:
        root = find_root(Path(files[0]).resolve())
    else:
        root = find_root(Path.cwd())

    if root is None:
        click.echo("error: could not locate repository root (flake.nix)", err=True)
        sys.exit(2)

    roots = collect_roots(root)
    if not roots:
        click.echo(f"error: no entry points found under {root}", err=True)
        sys.exit(2)

    reached = reachable_from(roots)
    orphans = sorted(all_nix_files(root) - reached)

    if not orphans:
        return
    click.echo("Orphaned .nix files (not imported anywhere):")
    for path in orphans:
        click.echo(f"  {path.relative_to(root)}")
    sys.exit(1)


if __name__ == "__main__":
    main(prog_name="nix-find-orphans")
