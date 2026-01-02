#!/usr/bin/env bash
# Get contents of a tab in Terminal.app

set -euo pipefail

show_help() {
    cat << EOF
Usage: tail-terminal.sh [OPTIONS]

Get contents of a tab in Terminal.app

Options:
  -l, --lines N     Number of lines to show (default: 20)
  -t, --tab N       Tab number or "selected" (default: selected)
  -w, --window N    Window number or "front" (default: front)
  -h, --help        Show this help message

Examples:
  tail-terminal.sh                        # 20 lines, selected tab, front window
  tail-terminal.sh --lines 50             # 50 lines, selected tab, front window
  tail-terminal.sh --lines 10 --tab 1 --window 2  # 10 lines, tab 1, window 2
EOF
    exit 0
}

lines=20
tab="selected"
window="front"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--lines)
            lines="$2"
            shift 2
            ;;
        -t|--tab)
            tab="$2"
            shift 2
            ;;
        -w|--window)
            window="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

if [[ "$tab" == "selected" ]]; then
    tab_selector="selected tab"
else
    tab_selector="tab $tab"
fi

if [[ "$window" == "front" ]]; then
    window_selector="front window"
else
    window_selector="window $window"
fi

osascript -e "tell application \"Terminal\" to get contents of $tab_selector of $window_selector" | tail -"$lines"
