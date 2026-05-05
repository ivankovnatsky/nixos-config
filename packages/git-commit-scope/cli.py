"""CLI orchestration for git-commit-scope."""

import os
import subprocess
import sys

import click

from ai import try_ai_shorten
from git import (
    get_all_changed_files,
    get_deleted_files,
    get_git_root,
    get_rename_sources_for_path,
    get_staged_renames,
    get_untracked_files,
    is_deleted,
    is_file_path,
    is_ignored,
    is_new_file,
    is_staged_deletion,
    is_staged_deletion_dir,
    is_staged_path,
    is_untracked,
    normalize_target_path,
)
from scope import (
    MAX_MESSAGE_LENGTH,
    changes_are_only_renames,
    compress_path,
    create_commit_message,
    create_rename_message,
    shorten_directories,
    shorten_path,
    validate_title,
)


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
            if is_new_file(args[0]):
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
  git-commit-scope f1.nix f2.nix "add feature"       Two separate commits, each with own scope
  git-commit-scope "add feature" -b "Body text"      Commits with subject and body
  git-commit-scope "add feature" -b "L1" -b "L2"     Multiple -b joined with newline
  git-commit-scope -s "add feature" -b "Line 1
  Line 2"                                            Multiline body with newlines
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
            if changes_are_only_renames(all_files, renames):
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
                if changes_are_only_renames(all_files, renames):
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
            click.echo(f"Title validation failed for {target_file}:", err=True)
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
                suggested = try_ai_shorten(commit_subject, max_subject)
                if suggested:
                    click.echo(f"  ai suggestion: {suggested}", err=True)
                    commit_subject = suggested
                    message = create_commit_message(prefix, commit_subject)
                    remaining = validate_title(message)
                    if remaining:
                        click.echo("AI suggestion still invalid:", err=True)
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
