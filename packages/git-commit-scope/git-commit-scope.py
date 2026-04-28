#!/usr/bin/env python3

"""
Git commit subject scope helper that auto-generates scope from file or directory paths.
"""

import json
import os
import re
import shutil
import subprocess
import sys

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

AI_SHORTEN_PROMPT = """Shorten this git commit subject to STRICTLY {max_chars} characters or fewer. Count carefully.
Output ONLY the shortened subject — no quotes, no backticks, no explanation, no trailing period.
Keep the core meaning. Use common abbreviations (config, auth, env, db, etc.) if needed.

Subject: {subject}
Max chars: {max_chars}"""

AI_BACKENDS = [
    {
        "name": "claude",
        "cmd": [
            "claude",
            "-p",
            "{prompt}",
            "--model",
            "claude-haiku-4-5-20251001",
            "--output-format",
            "json",
        ],
        "parse": "json",
        "json_key": "result",
    },
    {
        "name": "codex",
        "cmd": [
            "codex",
            "exec",
            "--ephemeral",
            "--skip-git-repo-check",
            "-m",
            "gpt-5.3-codex-spark",
            "{prompt}",
        ],
        "parse": "codex",
    },
    {
        "name": "gemini",
        "cmd": [
            "gemini",
            "--prompt",
            "{prompt}",
            "-m",
            "gemini-2.5-flash-lite",
            "--output-format",
            "json",
        ],
        "parse": "json",
        "json_key": "response",
    },
]


def _try_ai_shorten(subject: str, max_chars: int) -> str | None:
    """Try AI backends to shorten a commit subject. Returns shortened subject or None."""
    prompt = AI_SHORTEN_PROMPT.format(max_chars=max_chars, subject=subject)

    for backend in AI_BACKENDS:
        bin_name = backend["cmd"][0]
        if not shutil.which(bin_name):
            click.echo(f"  ai: {backend['name']} not found, skipping", err=True)
            continue

        cmd = [s.replace("{prompt}", prompt) for s in backend["cmd"]]
        click.echo(f"  ai: trying {backend['name']}...", err=True)

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=60,
                stdin=subprocess.DEVNULL,
            )
            if result.returncode != 0:
                click.echo(
                    f"  ai: {backend['name']} failed (exit {result.returncode})",
                    err=True,
                )
                continue

            shortened = _parse_ai_output(result.stdout, backend)
            if not shortened:
                click.echo(f"  ai: {backend['name']} returned empty output", err=True)
                continue

            if len(shortened) > max_chars:
                click.echo(
                    f"  ai: {backend['name']} suggestion too long: "
                    f"{len(shortened)} chars ({shortened!r})",
                    err=True,
                )
                continue

            return shortened

        except subprocess.TimeoutExpired:
            click.echo(f"  ai: {backend['name']} timed out", err=True)
            continue
        except Exception as e:
            click.echo(f"  ai: {backend['name']} error: {e}", err=True)
            continue

    return None


def _parse_ai_output(stdout: str, backend: dict) -> str | None:
    """Parse AI backend output to extract just the suggested subject."""
    parse_mode = backend.get("parse", "text")

    if parse_mode == "json":
        try:
            data = json.loads(stdout)
            key = backend.get("json_key", "result")
            text = data.get(key, "")
        except (json.JSONDecodeError, KeyError):
            text = stdout
    elif parse_mode == "codex":
        # Codex dumps headers then the response, duplicated at the end.
        # Take the last non-empty line that isn't metadata.
        lines = stdout.strip().split("\n")
        text = ""
        for line in reversed(lines):
            line = line.strip()
            if line and not line.startswith(
                ("---", "user", "codex", "tokens", "Reading")
            ):
                text = line
                break
    else:
        text = stdout.strip()

    if not text:
        return None

    # Strip common AI artifacts
    text = text.strip().strip("`\"'").strip()
    # Remove trailing period if added
    text = text.rstrip(".")
    return text if text else None


def get_git_root() -> str:
    """Get the root directory of the git repository."""
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def get_staged_files() -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--staged", "--name-only"],
        capture_output=True,
        text=True,
        check=True,
    )
    files = [f for f in result.stdout.strip().split("\n") if f]
    return files


def get_modified_files() -> list[str]:
    """Get tracked files that have been modified but not staged."""
    result = subprocess.run(
        ["git", "diff", "--name-only"],
        capture_output=True,
        text=True,
        check=True,
    )
    files = [f for f in result.stdout.strip().split("\n") if f]
    return files


def get_untracked_files() -> list[str]:
    git_root = get_git_root()
    result = subprocess.run(
        ["git", "ls-files", "--others", "--exclude-standard", "--full-name"],
        capture_output=True,
        text=True,
        check=True,
        cwd=git_root,
    )
    files = [f for f in result.stdout.strip().split("\n") if f]
    return files


def get_deleted_files() -> list[str]:
    """Get tracked files deleted from the working tree or staged for deletion."""
    unstaged = subprocess.run(
        ["git", "diff", "--diff-filter=D", "--name-only"],
        capture_output=True,
        text=True,
        check=True,
    )
    staged = subprocess.run(
        ["git", "diff", "--staged", "--diff-filter=D", "--name-only"],
        capture_output=True,
        text=True,
        check=True,
    )
    seen = dict()
    for f in unstaged.stdout.strip().split("\n") + staged.stdout.strip().split("\n"):
        if f:
            seen[f] = True
    return list(seen.keys())


def get_all_changed_files() -> list[str]:
    """Get all changed files: staged + modified + untracked, deduplicated."""
    staged = get_staged_files()
    modified = get_modified_files()
    untracked = get_untracked_files()
    seen = dict()
    for f in staged + modified + untracked:
        if f not in seen:
            seen[f] = True
    return list(seen.keys())


def get_staged_renames() -> list[tuple[str, str]]:
    """Get pure staged renames (R100 only) as (old_path, new_path) pairs.

    Only matches R100 (identical content). Edited renames (R050, R075, etc.)
    are excluded so the commit message doesn't hide content changes.
    """
    result = subprocess.run(
        ["git", "diff", "--staged", "-M", "--diff-filter=R", "--name-status"],
        capture_output=True,
        text=True,
        check=True,
    )
    renames = []
    for line in result.stdout.strip().split("\n"):
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) >= 3 and parts[0] == "R100":
            renames.append((parts[1], parts[2]))
    return renames


def get_rename_sources_for_path(target: str) -> list[str]:
    """Find source paths of staged renames whose destination is under target.

    When committing a directory, files renamed INTO it have their old (deleted)
    path outside the directory pathspec. This returns those old paths so they
    can be included in the commit.
    """
    try:
        result = subprocess.run(
            ["git", "diff", "--staged", "-M", "--diff-filter=R", "--name-status"],
            capture_output=True,
            text=True,
            check=True,
        )
    except subprocess.CalledProcessError:
        return []
    target_normalized = target.rstrip("/")
    sources = []
    for line in result.stdout.strip().split("\n"):
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) >= 3 and parts[0].startswith("R"):
            old_path, new_path = parts[1], parts[2]
            if new_path == target_normalized or new_path.startswith(
                target_normalized + "/"
            ):
                sources.append(old_path)
    return sources


def is_untracked(file_path: str, git_root: str) -> bool:
    """Check if a file is untracked by git."""
    result = subprocess.run(
        ["git", "ls-files", "--error-unmatch", file_path],
        capture_output=True,
        text=True,
        cwd=git_root,
    )
    return result.returncode != 0


def is_ignored(file_path: str, git_root: str) -> bool:
    """Check if a file is ignored by .gitignore."""
    result = subprocess.run(
        ["git", "check-ignore", "-q", file_path],
        capture_output=True,
        text=True,
        cwd=git_root,
    )
    return result.returncode == 0


def is_staged_path(path: str) -> bool:
    """Check if a path is in the staged files (works for deleted files too)."""
    try:
        result = subprocess.run(
            ["git", "diff", "--staged", "--name-only"],
            capture_output=True,
            text=True,
            check=True,
        )
        staged = [f for f in result.stdout.strip().split("\n") if f]
        # Normalize the input path for comparison
        abs_path = os.path.abspath(path)
        try:
            git_root = subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                capture_output=True,
                text=True,
                check=True,
            ).stdout.strip()
            rel_path = os.path.relpath(abs_path, git_root)
        except subprocess.CalledProcessError:
            rel_path = path
        return rel_path in staged or path in staged
    except subprocess.CalledProcessError:
        return False


def is_staged_deletion(path: str) -> bool:
    """Check if a path is staged as a deletion."""
    try:
        result = subprocess.run(
            ["git", "diff", "--staged", "--diff-filter=D", "--name-only"],
            capture_output=True,
            text=True,
            check=True,
        )
        deleted = [f for f in result.stdout.strip().split("\n") if f]
        abs_path = os.path.abspath(path)
        try:
            git_root = subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                capture_output=True,
                text=True,
                check=True,
            ).stdout.strip()
            rel_path = os.path.relpath(abs_path, git_root)
        except subprocess.CalledProcessError:
            rel_path = path
        return rel_path in deleted or path in deleted
    except subprocess.CalledProcessError:
        return False


def is_deleted(path: str) -> bool:
    """Check if a path is deleted from the working tree or staged for deletion."""
    try:
        deleted = get_deleted_files()
        abs_path = os.path.abspath(path)
        try:
            git_root = get_git_root()
            rel_path = os.path.relpath(abs_path, git_root)
        except subprocess.CalledProcessError:
            rel_path = path
        return rel_path in deleted or path in deleted
    except subprocess.CalledProcessError:
        return False


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


MIN_SCOPE_SEGMENTS = 2


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


def _changes_are_only_renames(
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


def _commit_renames(
    renames: list[tuple[str, str]], body_str: str | None, git_root: str
):
    """Commit staged renames with arrow notation messages."""
    os.environ["GIT_COMMIT_SCOPE_CLI"] = "1"
    if len(renames) > 1:
        click.echo("Multiple renames detected:", err=True)
        for old, new in renames:
            click.echo(f"  {old} -> {new}", err=True)
        click.echo("Commit them individually or use git commit directly", err=True)
        sys.exit(1)
    old_path, new_path = renames[0]
    message = create_rename_message(old_path, new_path)
    if len(message) > MAX_MESSAGE_LENGTH:
        click.echo(
            f"Message too long: {len(message)} chars (max {MAX_MESSAGE_LENGTH})",
            err=True,
        )
        click.echo(f"Message: {message}", err=True)
        sys.exit(1)
    click.echo(f"  commit rename {old_path} -> {new_path}")
    cmd = ["git", "commit", "-m", message]
    if body_str:
        cmd.extend(["-m", body_str])
    try:
        subprocess.run(cmd, check=True, cwd=git_root)
    except subprocess.CalledProcessError as e:
        click.echo(f"Git commit failed: {e}", err=True)
        sys.exit(1)


def is_git_tracked(path: str) -> bool:
    """Check if a path is tracked by git (exists in index, even if deleted from disk)."""
    try:
        abs_path = os.path.abspath(path)
        git_root = get_git_root()
        rel_path = os.path.relpath(abs_path, git_root)
        result = subprocess.run(
            ["git", "ls-files", "--error-unmatch", rel_path],
            capture_output=True,
            text=True,
            cwd=git_root,
        )
        return result.returncode == 0
    except (subprocess.CalledProcessError, Exception):
        return False


def _is_parent_of_changed(rel_path: str, changed: list[str]) -> bool:
    """Check if rel_path is a directory that contains any changed file."""
    prefix = rel_path.rstrip("/") + "/"
    return any(f.startswith(prefix) for f in changed)


def is_staged_deletion_dir(path: str) -> bool:
    """True if path is a directory that no longer exists and contains staged deletions."""
    try:
        abs_path = os.path.abspath(path)
        if os.path.exists(abs_path):
            return False
        git_root = get_git_root()
        rel_path = os.path.relpath(abs_path, git_root)
        deleted = get_deleted_files()
        return _is_parent_of_changed(rel_path, deleted) or _is_parent_of_changed(
            path, deleted
        )
    except subprocess.CalledProcessError:
        return False


def is_file_path(path: str) -> bool:
    """Check if path is a file (exists on disk, is staged, or is tracked by git).

    Checks both relative to CWD and relative to git root. Also accepts a
    directory path that contains staged or deleted files but no longer exists
    on disk (e.g., a directory whose entire contents were deleted).
    """
    if os.path.exists(path) or is_staged_path(path) or is_git_tracked(path):
        return True
    try:
        git_root = get_git_root()
        abs_from_root = os.path.join(git_root, path)
        if os.path.exists(abs_from_root):
            return True
        root_rel_path = os.path.relpath(abs_from_root, git_root)
        cwd_rel_path = os.path.relpath(os.path.abspath(path), git_root)
        staged = get_staged_files()
        deleted = get_deleted_files()
        if root_rel_path in staged or root_rel_path in deleted:
            return True
        # Directory whose contents are staged/deleted (no longer on disk).
        changed = staged + deleted
        for candidate in (root_rel_path, cwd_rel_path, path):
            if _is_parent_of_changed(candidate, changed):
                return True
        result = subprocess.run(
            ["git", "ls-files", "--error-unmatch", root_rel_path],
            capture_output=True,
            text=True,
            cwd=git_root,
        )
        if result.returncode == 0:
            return True
    except subprocess.CalledProcessError:
        pass
    return False


def _is_new_file(path: str) -> bool:
    """Check if a path is new to the repo (not in HEAD), for defaulting subject to 'init'.

    This covers both untracked files and staged-but-never-committed files.
    For directories, checks whether HEAD has any files under that path.
    """
    try:
        git_root = get_git_root()
        abs_path = os.path.abspath(path)
        rel_path = os.path.relpath(abs_path, git_root)
        if os.path.isdir(abs_path):
            # For directories, check if HEAD has any files under this path
            result = subprocess.run(
                ["git", "ls-tree", "-r", "HEAD", "--", rel_path],
                capture_output=True,
                text=True,
                cwd=git_root,
            )
            return result.returncode == 0 and not result.stdout.strip()
        result = subprocess.run(
            ["git", "cat-file", "-e", f"HEAD:{rel_path}"],
            capture_output=True,
            text=True,
            cwd=git_root,
        )
        return result.returncode != 0
    except subprocess.CalledProcessError:
        return False


def infer_no_arg_commit() -> tuple[list[str], str]:
    """Infer a commit target and subject for bare `git-commit-scope`.

    Bare mode is deliberately narrow: it only defaults new untracked files to
    "init" and deleted files to "remove". Modified files still need an explicit
    subject so the command does not guess at intent.
    """
    try:
        all_files = get_all_changed_files()
    except subprocess.CalledProcessError as e:
        click.echo(f"Failed to get changed files: {e}", err=True)
        sys.exit(1)

    if not all_files:
        click.echo("No changed files", err=True)
        sys.exit(1)

    if len(all_files) != 1:
        click.echo(
            f"Expected 1 changed file, found {len(all_files)}:",
            err=True,
        )
        for f in all_files:
            click.echo(f"  {f}", err=True)
        sys.exit(1)

    target = all_files[0]
    untracked = get_untracked_files()
    deleted = get_deleted_files()

    if target in untracked and target in deleted:
        click.echo(
            "Error: Subject required for replaced files in no-argument mode",
            err=True,
        )
        click.echo("  Use: git-commit-scope <file> -s 'subject'", err=True)
        click.echo("  Or:  git-commit-scope <file> 'subject'", err=True)
        sys.exit(1)

    if target in deleted:
        return [target], "remove"
    if target in untracked:
        return [target], "init"

    click.echo(
        "Error: Subject required for modified files in no-argument mode",
        err=True,
    )
    click.echo(
        "  Bare git-commit-scope only defaults untracked files to 'init'",
        err=True,
    )
    click.echo("  and deleted files to 'remove'.", err=True)
    click.echo("  Use: git-commit-scope <file> -s 'subject'", err=True)
    click.echo("  Or:  git-commit-scope 'subject'", err=True)
    sys.exit(1)


def normalize_target_path(path: str, git_root: str) -> str:
    """Normalize a user or git-reported path to be relative to the repo root."""
    abs_path = os.path.abspath(path)
    if os.path.exists(abs_path):
        return os.path.relpath(abs_path, git_root)

    abs_from_root = os.path.abspath(os.path.join(git_root, path))
    cwd_rel_path = os.path.relpath(abs_path, git_root)
    root_rel_path = os.path.relpath(abs_from_root, git_root)
    staged = get_staged_files()
    deleted = get_deleted_files()

    if cwd_rel_path in staged or cwd_rel_path in deleted:
        return cwd_rel_path

    if (
        os.path.exists(abs_from_root)
        or root_rel_path in staged
        or root_rel_path in deleted
        or path in staged
        or path in deleted
    ):
        return root_rel_path

    # Directory whose contents are staged/deleted (no longer on disk).
    changed = staged + deleted
    if _is_parent_of_changed(cwd_rel_path, changed):
        return cwd_rel_path
    if _is_parent_of_changed(root_rel_path, changed):
        return root_rel_path

    return cwd_rel_path


def parse_args_flexible(
    args: list[str], subject_flag: str | None
) -> tuple[list[str], str]:
    """Parse arguments flexibly: one or more files + subject.

    Returns (file_paths, subject) where file_paths may be empty (auto-detect).
    Supports:
      - git-commit-scope "subject"                  -> ([], subject)
      - git-commit-scope file "subject"             -> ([file], subject)
      - git-commit-scope "subject" file             -> ([file], subject)
      - git-commit-scope file1 file2 "subject"      -> ([file1, file2], subject)
      - git-commit-scope file1 file2 -s "subject"   -> ([file1, file2], subject)
      - git-commit-scope file                       -> ([file], "init") if new file
    """
    if subject_flag:
        # Subject provided via -s flag — all positional args must be files
        files = []
        for a in args:
            if is_file_path(a):
                files.append(a)
            else:
                click.echo(f"Error: File not found: {a}", err=True)
                sys.exit(1)
        return files, subject_flag

    if len(args) == 0:
        click.echo("Error: Subject required (use -s or positional arg)", err=True)
        sys.exit(1)

    # Original behavior for 1 arg
    if len(args) == 1:
        if is_file_path(args[0]):
            if _is_new_file(args[0]):
                return [args[0]], "init"
            click.echo(
                f"Error: '{args[0]}' looks like a file path, not a subject.",
                err=True,
            )
            click.echo(
                "  Use: git-commit-scope <file> -s 'subject'",
                err=True,
            )
            click.echo(
                "  Or:  git-commit-scope <file> 'subject'",
                err=True,
            )
            sys.exit(1)
        return [], args[0]

    # 2+ args: separate files from subject
    # Exactly one non-file arg is the subject; rest are files
    files = []
    non_files = []
    for a in args:
        if is_file_path(a):
            files.append(a)
        else:
            non_files.append(a)

    if len(non_files) == 1:
        return files, non_files[0]
    elif len(non_files) == 0:
        click.echo("Error: All arguments are file paths, no subject provided", err=True)
        click.echo("  Use: git-commit-scope <file>... -s 'subject'", err=True)
        sys.exit(1)
    else:
        click.echo(
            "Error: Multiple non-file arguments (expected exactly one subject):",
            err=True,
        )
        for nf in non_files:
            click.echo(f"  {nf}", err=True)
        sys.exit(1)


@click.command(
    epilog="""\b
Examples:
  git-commit-scope "add feature"                     Commits staged file with "<scope>: add feature"
  git-commit-scope file.nix "add feature"            Commits file.nix with "<scope>: add feature"
  git-commit-scope src/dir "add feature"             Commits all changes in src/dir
  git-commit-scope f1.nix f2.nix "add feature"      Two separate commits, each with own scope
  git-commit-scope "add feature" -b "Body text"      Commits with subject and body
  git-commit-scope "add feature" -b "L1" -b "L2"     Multiple -b joined with newline
  git-commit-scope -s "add feature" -b "Line 1
  Line 2"                                       Multiline body with newlines
  git-commit-scope                                   Single untracked file: commits "<scope>: init"
  git-commit-scope                                   Single deleted file: commits "<scope>: remove"
  git-commit-scope                                   After git mv: auto-detects rename, commits "old -> new"

Features:
  - Accepts one or more file/directory paths (auto-detected by existence)
  - Multiple files create separate commits, each with its own scope prefix
  - Directories commit all changes under that path
  - Auto-adds untracked files before committing
  - Without path arg but with subject, detects exactly one changed file
  - With no args, commits exactly one untracked file as init or deleted file as remove
  - Strips file extensions (e.g., .nix, .py)
  - Shortens machine names (e.g., Ivans-Mac-mini -> mini)
  - Removes duplicate path components (e.g., pkg/foo/foo -> pkg/foo)
  - Strips "default" filename (e.g., mod/foo/default -> mod/foo)
  - Shortens directories if message > 72 chars (packages->pkg, modules->mod, etc.)
  - Detects staged renames (git mv) and commits with arrow notation (old -> new)
  - Validates total message length (max 72 chars)
""",
    context_settings={"help_option_names": ["-h", "--help"]},
)
@click.argument("args", nargs=-1, metavar="[PATH...] [SUBJECT]")
@click.option(
    "-s",
    "--subject",
    default=None,
    help="commit subject (alternative to positional arg)",
)
@click.option(
    "-b",
    "--body",
    multiple=True,
    help="commit body (can use multiple times, joined with newline)",
)
@click.option(
    "--ai-shorten/--no-ai-shorten",
    default=True,
    help="use AI to shorten subject if too long (tries claude, codex, gemini)",
)
def main(args, subject, body, ai_shorten):
    """Auto-generate git commit subject scope from changed file paths."""
    # Join multiple -b flags with single newline (no blank lines)
    body_str = "\n".join(body) if body else None

    # Get git root early - needed for path normalization and rename detection
    try:
        git_root = get_git_root()
    except subprocess.CalledProcessError as e:
        click.echo(f"Failed to get git root: {e}", err=True)
        sys.exit(1)

    # Handle rename-only mode: no args needed after git mv
    if not args and not subject:
        try:
            renames = get_staged_renames()
        except subprocess.CalledProcessError:
            renames = []
        if renames:
            try:
                all_files = get_all_changed_files()
            except subprocess.CalledProcessError:
                all_files = []
            if _changes_are_only_renames(all_files, renames):
                _commit_renames(renames, body_str, git_root)
                return
            else:
                rename_paths = set()
                for old, new in renames:
                    rename_paths.add(old)
                    rename_paths.add(new)
                other_files = [f for f in all_files if f not in rename_paths]
                click.echo("Staged renames found but also other changes:", err=True)
                click.echo("  Renames:", err=True)
                for old, new in renames:
                    click.echo(f"    {old} -> {new}", err=True)
                click.echo("  Other files:", err=True)
                for f in other_files:
                    click.echo(f"    {f}", err=True)
                click.echo("Commit the renames separately or specify files", err=True)
                sys.exit(1)

    if not args and not subject:
        target_files, commit_subject = infer_no_arg_commit()
    else:
        file_paths, commit_subject = parse_args_flexible(list(args), subject)
        if file_paths:
            target_files = [normalize_target_path(fp, git_root) for fp in file_paths]
        else:
            try:
                all_files = get_all_changed_files()
            except subprocess.CalledProcessError as e:
                click.echo(f"Failed to get changed files: {e}", err=True)
                sys.exit(1)

            if not all_files:
                click.echo("No changed files", err=True)
                sys.exit(1)

            if len(all_files) != 1:
                # Check if changes are all renames
                try:
                    renames = get_staged_renames()
                except subprocess.CalledProcessError:
                    renames = []
                if _changes_are_only_renames(all_files, renames):
                    _commit_renames(renames, body_str, git_root)
                    return

                click.echo(
                    f"Expected 1 changed file, found {len(all_files)}:",
                    err=True,
                )
                for f in all_files:
                    click.echo(f"  {f}", err=True)
                sys.exit(1)

            target_files = [all_files[0]]

    # Set env var so pre-commit hook skips the "use git-commit-scope" hint
    os.environ["GIT_COMMIT_SCOPE_CLI"] = "1"

    # Up-front validation of subject-only rules (independent of per-file scope).
    # Catch semicolons here so we fail before any per-target work.
    subject_errors = []
    if ";" in commit_subject:
        subject_errors.append("Semicolons not allowed in commit title")
    if subject_errors:
        click.echo("Subject validation failed:", err=True)
        for e in subject_errors:
            click.echo(f"  - {e}", err=True)
        click.echo(f"Subject: {commit_subject}", err=True)
        sys.exit(1)

    def _too_long(p: str) -> bool:
        return len(create_commit_message(p, commit_subject)) > MAX_MESSAGE_LENGTH

    for target_file in target_files:
        prefix = shorten_path(target_file)

        if _too_long(prefix):
            prefix = shorten_directories(prefix)

        if _too_long(prefix):
            prefix = compress_path(prefix, commit_subject)

        message = create_commit_message(prefix, commit_subject)
        errors = validate_title(message)

        if errors:
            click.echo(
                f"Title validation failed for {target_file}:", err=True
            )
            for e in errors:
                click.echo(f"  - {e}", err=True)
            click.echo(f"Title: {message}", err=True)

            length_only = len(errors) == 1 and errors[0].startswith(
                "Commit title must be"
            )
            if length_only and ai_shorten:
                max_subject = MAX_MESSAGE_LENGTH - len(prefix) - len(": ")
                click.echo(
                    f"Subject must be ≤ {max_subject} chars "
                    f"(currently {len(commit_subject)})",
                    err=True,
                )
                suggested = _try_ai_shorten(commit_subject, max_subject)
                if suggested:
                    click.echo(f"  ai suggestion: {suggested}", err=True)
                    commit_subject = suggested
                    message = create_commit_message(prefix, commit_subject)
                    remaining = validate_title(message)
                    if remaining:
                        click.echo(
                            "AI suggestion still invalid:", err=True
                        )
                        for e in remaining:
                            click.echo(f"  - {e}", err=True)
                        sys.exit(1)
                else:
                    click.echo("  ai: all backends failed", err=True)
                    sys.exit(1)
            else:
                sys.exit(1)

        try:
            # Add untracked files first (git commit <file> only works for tracked files)
            # Skip if file is already staged (e.g., staged deletion)
            force_added = False
            dir_deletion = is_staged_deletion_dir(target_file)
            if dir_deletion:
                # Directory whose contents are all staged for deletion; nothing to add.
                pass
            elif is_staged_path(target_file):
                # File already staged — check if it's ignored (e.g., pre-staged with git add -f)
                force_added = is_ignored(target_file, git_root)
            elif is_untracked(target_file, git_root):
                result = subprocess.run(
                    ["git", "add", target_file],
                    capture_output=True,
                    text=True,
                    cwd=git_root,
                )
                if result.returncode != 0:
                    # Fall back to force-add (needed when .gitignore ignores the file)
                    click.echo(f"  add -f {target_file}")
                    subprocess.run(
                        ["git", "add", "-f", target_file], check=True, cwd=git_root
                    )
                    force_added = True
                else:
                    click.echo(f"  add {target_file}")
            elif is_deleted(target_file):
                subprocess.run(
                    ["git", "add", "--", target_file],
                    check=True,
                    cwd=git_root,
                )
                click.echo(f"  add {target_file}")

            click.echo(f"  commit {target_file}")

            rename_sources = get_rename_sources_for_path(target_file)
            for src in rename_sources:
                click.echo(f"  include rename source {src}")

            # For staged deletions, git commit <file> doesn't work because it reads
            # from the working tree (where the file no longer exists). Use --only
            # to commit just this path from the index without pulling in other staged changes.
            if is_staged_deletion(target_file) or dir_deletion:
                cmd = ["git", "commit", "--only", target_file, "-m", message]
            elif force_added:
                # Ignored files can't be used as pathspec (git respects .gitignore
                # in pathspec matching even after git add -f). Commit from index.
                cmd = ["git", "commit", "-m", message]
            else:
                cmd = ["git", "commit", target_file] + rename_sources + ["-m", message]
            if body_str:
                cmd.extend(["-m", body_str])
            subprocess.run(cmd, check=True, cwd=git_root)
        except subprocess.CalledProcessError as e:
            click.echo(f"Git commit failed: {e}", err=True)
            sys.exit(1)


if __name__ == "__main__":
    main(prog_name="git-commit-scope")
