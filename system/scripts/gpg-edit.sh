#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: gpg-edit <file.md>"
  echo ""
  echo "Creates and encrypts a new file, or opens an existing .gpg file for editing."
  echo "Uses the first GPG key found in your keyring."
  echo ""
  echo "Options:"
  echo "  -h, --help    Show this help message"
  exit 0
}

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
fi

file="$1"
gpg_file="${file%.gpg}"
gpg_file="${gpg_file}.gpg"

KEY_ID=$(gpg --list-keys --with-colons 2>/dev/null | grep '^pub' | head -1 | cut -d: -f5)

if [ -z "$KEY_ID" ]; then
  echo "Error: No GPG key found."
  exit 1
fi

if [ -f "$gpg_file" ]; then
  ${EDITOR:-nvim} "$gpg_file"
else
  tmp=$(mktemp /tmp/gpg-edit-XXXXXX.md)
  trap 'rm -f "$tmp"' EXIT

  ${EDITOR:-nvim} "$tmp"

  if [ -s "$tmp" ]; then
    gpg --encrypt --recipient "$KEY_ID" --output "$gpg_file" "$tmp"
    echo "Encrypted: $gpg_file"
  else
    echo "Empty file, nothing to encrypt."
  fi
fi
