#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: task-mgmt <command> [options]"
  echo ""
  echo "Commands:"
  echo "  rg <pattern>   Search tasks by pattern (case-insensitive)"
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

if [ $# -eq 0 ]; then
  usage
fi

case "$1" in
rg)
  shift
  cmd_rg "$@"
  ;;
*)
  echo "Unknown command: $1" >&2
  usage
  ;;
esac
