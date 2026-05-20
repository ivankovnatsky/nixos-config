#!/usr/bin/env bash

# grep-find — consolidated search tool (merges find-grep, rg-all, rg-find)
#
# Modes:
#   grep-find <search_term> [file_pattern]   Interactive rg + fzf preview, open in nvim (default)
#   grep-find --all <rg_args...>             rg ignoring all ignore files, including hidden
#   grep-find --find <search_term>           List matching file names, then content matches
#
# Examples:
#   grep-find "kafka:"                       # Search in all files (interactive)
#   grep-find "kafka:" "values.yaml"         # Search in values.yaml files (interactive)
#   grep-find "kafka:" ".yaml"               # Search in all yaml files (interactive)
#   grep-find --all "TODO"                   # Search everything, no ignore rules
#   grep-find --find config                  # List files/content matching 'config'

case "${1:-}" in
--all)
  shift
  clear
  exec rg \
    --no-ignore \
    --no-ignore-dot \
    --no-ignore-exclude \
    --no-ignore-files \
    --no-ignore-global \
    --no-ignore-parent \
    --no-ignore-vcs \
    --hidden \
    "$@"
  ;;
--find)
  shift
  echo "Searching files.."
  rg --files | rg -i "$@"
  echo ""
  echo "--"
  echo ""
  echo "Searching in files.."
  rg -i "$@"
  ;;
*)
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
  ;;
esac
