#!/usr/bin/env bash
set -euo pipefail

# Wrapper around genpass that defaults to --include-digit --include-lowercase
# --include-uppercase (no special characters). When --passphrase is passed,
# defaults to at least 20 chars with hyphens replacing spaces.

passphrase=false
for arg in "$@"; do
  if [ "$arg" = "--passphrase" ]; then
    passphrase=true
    break
  fi
done

if [ "$passphrase" = true ]; then
  # Default to at least 20 chars with hyphens as separator
  has_length=false
  for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
      has_length=true
      break
    fi
  done
  if [ "$has_length" = true ]; then
    @genpass@ "$@" | tr ' ' '-'
  else
    @genpass@ "$@" 20 | tr ' ' '-'
  fi
else
  exec @genpass@ --include-digit --include-lowercase --include-uppercase "$@"
fi
