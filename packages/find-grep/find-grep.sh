#!/usr/bin/env bash

# find-grep — consolidated search tool
#
# Modes:
#   find-grep <search_term>                      Find files (fzf+nvim), then grep content (default)
#   find-grep --interactive <term> [pattern]     Interactive rg + fzf preview, open in nvim
#   find-grep --all <rg_args...>                 rg ignoring all ignore files, including hidden
#
# Examples:
#   find-grep "kafka:"                           # Find files, open in nvim, then grep content
#   find-grep --interactive "kafka:"             # Interactive content search with fzf
#   find-grep --interactive "kafka:" "values.yaml"  # Interactive fzf, filtered by file pattern
#   find-grep --all "TODO"                       # Search everything, no ignore rules

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
--interactive)
  shift
  search_term="$1"
  file_pattern="${2:-}"

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
  ;;
*)
  rg --files | rg -i "$@" |
    fzf --preview 'bat --style=numbers --color=always {}' \
      --bind 'enter:execute(nvim {})'

  echo ""
  echo "Content:"
  rg -i --color=always --line-number "$@" |
    fzf --ansi \
      --delimiter : \
      --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
      --preview-window '+{2}-/2' \
      --bind 'enter:execute(nvim {1} +{2})'
  ;;
esac
