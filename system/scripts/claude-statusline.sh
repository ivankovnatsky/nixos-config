#!/usr/bin/env bash

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
SESSION_ID=$(echo "$input" | jq -r '.session_id // ""')
INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
CACHE_READ=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'
MAGENTA='\033[35m'; BLUE='\033[34m'; DIM='\033[90m'; RESET='\033[0m'

# Line 1: model | dir | git
LINE1="${CYAN}${MODEL}${RESET}"
LINE1="${LINE1} ${DIM}|${RESET} ${DIR}"

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

# Line 2: context bar | cost | duration | tokens
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 5)); EMPTY=$((20 - FILLED))
BAR=$(printf "%${FILLED}s" | tr ' ' '▓')$(printf "%${EMPTY}s" | tr ' ' '░')

COST_FMT=$(printf '$%.2f' "$COST")
MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))

# Format token counts (e.g., 15234 -> 15.2k)
fmt_tokens() {
    local n=$1
    if [ "$n" -ge 1000000 ]; then
        printf '%.1fM' "$(echo "$n / 1000000" | bc -l)"
    elif [ "$n" -ge 1000 ]; then
        printf '%.1fk' "$(echo "$n / 1000" | bc -l)"
    else
        printf '%d' "$n"
    fi
}

IN_FMT=$(fmt_tokens "$INPUT_TOKENS")
OUT_FMT=$(fmt_tokens "$OUTPUT_TOKENS")
CACHE_FMT=$(fmt_tokens "$CACHE_READ")
CTX_FMT=$(fmt_tokens "$CTX_SIZE")

printf '%b\n' "${BAR_COLOR}${BAR}${RESET} ${PCT}% ${DIM}|${RESET} ${YELLOW}${COST_FMT}${RESET} ${DIM}|${RESET} ${MINS}m${SECS}s ${DIM}|${RESET} ${GREEN}in:${IN_FMT}${RESET} ${YELLOW}out:${OUT_FMT}${RESET} ${BLUE}cache:${CACHE_FMT}${RESET} ${DIM}ctx:${CTX_FMT}${RESET}"
