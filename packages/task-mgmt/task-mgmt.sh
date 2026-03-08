#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: task-mgmt <command> [options]"
  echo ""
  echo "Commands:"
  echo "  rg <pattern>   Search tasks by pattern (case-insensitive)"
  echo "  view           View pending tasks sorted by urgency"
  exit 1
}

cmd_rg() {
  if [ $# -eq 0 ]; then
    echo "Usage: task-mgmt rg <pattern>" >&2
    exit 1
  fi

  local pattern="$1"
  task rc.verbose=nothing rc.detection=off rc.defaultwidth=0 all 2>/dev/null | rg -i "$pattern"
}

cmd_view() {
  task export rc.verbose=nothing 2>/dev/null | nu -c '
    $in | from json
    | where status == "pending"
    | select id project? description due? urgency tags?
    | sort-by -r urgency
    | table
  '
}

if [ $# -eq 0 ]; then
  usage
fi

case "$1" in
rg)
  shift
  cmd_rg "$@"
  ;;
view)
  cmd_view
  ;;
*)
  echo "Unknown command: $1" >&2
  usage
  ;;
esac
