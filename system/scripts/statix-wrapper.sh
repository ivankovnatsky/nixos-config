#!/usr/bin/env bash
# shellcheck shell=bash
# Wrapper script for statix that handles multiple files from treefmt
# statix expects a single target, so we run it on each file individually

set -euo pipefail

if [[ $# -eq 0 ]]; then
  exit 0
fi

exit_code=0
for file in "$@"; do
  if ! statix fix "$file"; then
    exit_code=1
  fi
done

exit $exit_code
