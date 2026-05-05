"""Git/filesystem operations for git-commit-scope."""

import os
import subprocess


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


def is_new_file(path: str) -> bool:
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
