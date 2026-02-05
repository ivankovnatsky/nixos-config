#!/usr/bin/env bash

# Usage: find-grep <search_term> [file_pattern]
#
# Examples:
#   find-grep "kafka:"                    # Search in all files
#   find-grep "kafka:" "values"           # Search in files containing 'values'
#   find-grep "kafka:" "values.yaml"      # Search in values.yaml files
#   find-grep "kafka:" ".yaml"            # Search in all yaml files
#   find-grep "kafka:" "config/dev/"      # Search in files under config/dev/
#   find-grep "kafka:" "dir/dir2/file"    # Search in files containing 'file' in dir/dir2/

search_term="$1"
file_pattern="${2:-}" # Optional file pattern argument

# Try ripgrep with fzf preview for content, using file pattern if provided
if [ -n "$file_pattern" ]; then
  rg --no-ignore --hidden --color=always --line-number "$search_term" -g "**/*${file_pattern}*" |
    fzf --ansi \
      --delimiter : \
      --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
      --preview-window '+{2}-/2' \
      --bind 'enter:execute(nvim {1} +{2})'
else
  rg --no-ignore --hidden --color=always --line-number "$search_term" |
    fzf --ansi \
      --delimiter : \
      --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
      --preview-window '+{2}-/2' \
      --bind 'enter:execute(nvim {1} +{2})'
fi

# Always run fzf file search after content search, without file pattern restriction
fzf --preview 'bat --style=numbers --color=always {}' \
  --query "$search_term" \
  --bind 'enter:execute(nvim {})'
