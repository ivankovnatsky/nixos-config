#!/usr/bin/env bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ]; then
  exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

TREEFMT=$(command -v treefmt || echo "/etc/profiles/per-user/ivan/bin/treefmt")
if [ ! -x "$TREEFMT" ]; then
  exit 0
fi

"$TREEFMT" "$FILE_PATH" 2>/dev/null
exit 0
