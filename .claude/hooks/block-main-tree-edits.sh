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
  echo "Main tree must stay on $BRANCH. Create a worktree with 'gwq-add' and edit there." >&2

  GWQ_ADD=$(command -v gwq-add || echo "/etc/profiles/per-user/ivan/bin/gwq-add")
  if [ -x "$GWQ_ADD" ]; then
    GWQ_OUTPUT=$(cd "$TOPLEVEL" && "$GWQ_ADD" 2>&1)
    GWQ_STATUS=$?
    if [ $GWQ_STATUS -eq 0 ]; then
      echo "Auto-created worktree:" >&2
      echo "$GWQ_OUTPUT" >&2
      echo "cd into it and retry the edit there." >&2
    else
      echo "gwq-add failed:" >&2
      echo "$GWQ_OUTPUT" >&2
    fi
  fi

  exit 2
fi

exit 0
