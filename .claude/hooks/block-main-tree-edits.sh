#!/usr/bin/env bash

# Block Edit/Write/NotebookEdit on files whose enclosing git repo has
# main/master checked out. Forces use of a worktree branch.
#
# Only fires when the target file lives in the SAME repo as
# $CLAUDE_PROJECT_DIR. Edits to files in other repos (home dotfiles,
# Obsidian notes vault, etc.) are ignored regardless of their branch.
# Without this check, working in nix-config would block edits to the
# log under ~/Notes because $HOME is itself a git repo on main.

INPUT=$(cat)
# NotebookEdit uses notebook_path instead of file_path.
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path')

if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ]; then
  exit 0
fi

# File may not exist yet (Write of a new file); walk up to a real dir.
DIR=$(dirname "$FILE_PATH")
while [ ! -d "$DIR" ] && [ "$DIR" != "/" ]; do
  DIR=$(dirname "$DIR")
done

GIT=$(command -v git || echo "/etc/profiles/per-user/ivan/bin/git")
if [ ! -x "$GIT" ]; then
  exit 0
fi

# Not inside a git repo -> allow. stderr suppressed: failure here means
# "not a repo", which is the expected, allow-path signal.
TOPLEVEL=$("$GIT" -C "$DIR" rev-parse --show-toplevel 2>/dev/null)
if [ -z "$TOPLEVEL" ]; then
  exit 0
fi

# Only act on files in the same repo Claude is running in. Without
# $CLAUDE_PROJECT_DIR we can't tell, so allow.
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  exit 0
fi
PROJECT_TOPLEVEL=$("$GIT" -C "$CLAUDE_PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null)
if [ -z "$PROJECT_TOPLEVEL" ] || [ "$TOPLEVEL" != "$PROJECT_TOPLEVEL" ]; then
  exit 0
fi

BRANCH=$("$GIT" -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo "BLOCKED: $FILE_PATH is in the main tree of $TOPLEVEL (branch=$BRANCH)." >&2
  echo "Main tree must stay on $BRANCH. Auto-creating (or reusing) a worktree below." >&2

  # Reuse the last auto-created worktree if it still exists. Without this,
  # every blocked Edit/Write on main would spawn another random worktree,
  # since exit 2 means the agent never moves into the one we just made.
  # flock serializes concurrent agents so they don't each create one.
  SENTINEL="$TOPLEVEL/.git/claude-auto-worktree"
  LOCK="$TOPLEVEL/.git/claude-auto-worktree.lock"
  FLOCK=$(command -v flock || echo "/run/current-system/sw/bin/flock")
  GWQ_ADD=$(command -v gwq-add || echo "/etc/profiles/per-user/ivan/bin/gwq-add")

  WORKTREE_PATH=$(
    if [ -x "$FLOCK" ]; then
      exec 9>"$LOCK"
      "$FLOCK" -x 9
    fi
    # Re-check sentinel under the lock in case a sibling agent just wrote it.
    if [ -f "$SENTINEL" ]; then
      CACHED=$(cat "$SENTINEL" 2>/dev/null)
      if [ -n "$CACHED" ] && [ -d "$CACHED" ]; then
        echo "$CACHED"
        exit 0
      fi
    fi
    if [ -x "$GWQ_ADD" ]; then
      # gwq-add writes progress to stderr and the worktree path to stdout
      # (via `gwq get`). Let stderr pass through; capture stdout only.
      NEW=$(cd "$TOPLEVEL" && "$GWQ_ADD")
      if [ -n "$NEW" ] && [ -d "$NEW" ]; then
        echo "$NEW" >"$SENTINEL"
        echo "$NEW"
      fi
    fi
  )

  if [ -n "$WORKTREE_PATH" ]; then
    REL="${FILE_PATH#"$TOPLEVEL/"}"
    echo "Auto-created/reused worktree: $WORKTREE_PATH" >&2
    echo "Retry the edit against: $WORKTREE_PATH/$REL" >&2
  else
    echo "Could not auto-create a worktree (gwq-add missing or failed)." >&2
    echo "Run 'gwq-add' manually and retry the edit there." >&2
  fi

  exit 2
fi

exit 0
