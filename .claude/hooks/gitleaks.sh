#!/usr/bin/env bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ]; then
  exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Skip non-text files and common binary extensions
case "$FILE_PATH" in
*.png | *.jpg | *.jpeg | *.gif | *.ico | *.woff | *.woff2 | *.ttf | *.eot | *.pdf | *.zip | *.tar | *.gz)
  exit 0
  ;;
esac

# Skip if gitleaks is not installed
GITLEAKS=$(command -v gitleaks || echo "/etc/profiles/per-user/ivan/bin/gitleaks")
if [ ! -x "$GITLEAKS" ]; then
  exit 0
fi

# Scan file contents via stdin subcommand (no temp dir needed)
RESULT=$(cat "$FILE_PATH" | "$GITLEAKS" stdin --no-banner --no-color --exit-code 1 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "BLOCKED: gitleaks detected potential secrets in $FILE_PATH"
  echo "$RESULT"
  echo ""
  echo "If this is a false positive, add a 'gitleaks:allow' comment on the line."
  exit 2
fi

exit 0
