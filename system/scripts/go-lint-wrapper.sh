#!/usr/bin/env bash
# shellcheck shell=bash
# Wrapper script for golangci-lint that handles files from multiple directories
# treefmt passes all files at once, but Go tools require files from same directory

set -euo pipefail

# Set GOPATH if not set
export GOPATH="${GOPATH:-$HOME/go}"
export GO111MODULE=off

if [[ $# -eq 0 ]]; then
  exit 0
fi

# Group files by directory and run golangci-lint on each
declare -A dirs
for file in "$@"; do
  dir=$(dirname "$file")
  dirs[$dir]=1
done

exit_code=0
for dir in "${!dirs[@]}"; do
  if ! golangci-lint run --fix "$dir/"; then
    exit_code=1
  fi
done

exit $exit_code
