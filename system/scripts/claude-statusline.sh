#!/usr/bin/env bash

# https://code.claude.com/docs/en/statusline

input=$(cat)

MODEL_ID=$(echo "$input" | jq -r '.model.id')
CWD=$(echo "$input" | jq -r '.workspace.current_dir')
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir')
REMAINING=$(echo "$input" | jq -r '.context_window.remaining_percentage // 100' | cut -d. -f1)
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // ""')

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'
MAGENTA='\033[35m'; BLUE='\033[34m'; DIM='\033[90m'; RESET='\033[0m'

# Format context size (e.g., 200000 -> 200k)
if [ "$CTX_SIZE" -ge 1000000 ]; then
    CTX_FMT="$(echo "$CTX_SIZE / 1000000" | bc -l | sed 's/\.0*$//')M"
else
    CTX_FMT="$((CTX_SIZE / 1000))k"
fi

# Line 1: model | context remaining | git branch + status
LINE1="${CYAN}${MODEL_ID}${RESET} ${DIM}|${RESET} ${REMAINING}% remaining ${DIM}|${RESET} ${DIM}ctx:${CTX_FMT}${RESET}"
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    STAGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    MODIFIED=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    GIT_STATUS=""
    [ "$STAGED" -gt 0 ] && GIT_STATUS="${GREEN}+${STAGED}${RESET}"
    [ "$MODIFIED" -gt 0 ] && GIT_STATUS="${GIT_STATUS}${YELLOW}~${MODIFIED}${RESET}"
    LINE1="${LINE1} ${DIM}|${RESET} ${MAGENTA}${BRANCH}${RESET} ${GIT_STATUS}"
fi
printf '%b\n' "$LINE1"

# Line 2: pwd (project dir)
printf '%b\n' "${DIM}pwd:${RESET} ${PROJECT_DIR}"

# Line 3: cwd (always shown)
printf '%b\n' "${DIM}cwd:${RESET} ${CWD}"

# Transcript path
[ -n "$TRANSCRIPT" ] && printf '%b\n' "${DIM}transcript:${RESET} ${TRANSCRIPT}"
