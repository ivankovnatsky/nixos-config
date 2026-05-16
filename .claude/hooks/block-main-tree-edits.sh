#!/usr/bin/env bash

# Block Edit/Write/NotebookEdit on files whose enclosing git repo has
# main/master checked out. Forces use of a worktree branch.
#
# Scoped to this repo via $CLAUDE_PROJECT_DIR in .claude/settings.json.
# Do NOT promote to user-global settings without an allowlist: the home
# dotfiles repo (~) and the Obsidian notes vault are intentionally
# main-only and edits there would be wrongly blocked.

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

BRANCH=$("$GIT" -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo "BLOCKED: $FILE_PATH is in the main tree of $TOPLEVEL (branch=$BRANCH)." >&2
  echo "Main tree must stay on $BRANCH. Create a worktree with 'gwq-add' and edit there." >&2
  exit 2
fi

exit 0
