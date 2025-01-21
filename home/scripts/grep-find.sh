#!/usr/bin/env bash

search_term="$1"

# Try ripgrep with fzf preview for content
rg --color=always --line-number "$search_term" | \
    fzf --ansi \
        --delimiter : \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
        --preview-window '+{2}-/2' \
        --bind 'enter:execute(nvim {1} +{2})'

# Always run fzf file search after content search
fzf --preview 'bat --style=numbers --color=always {}' \
    --query "$search_term" \
    --bind 'enter:execute(nvim {})'
