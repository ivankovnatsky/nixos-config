#!/usr/bin/env bash

# Simple wrapper script to generate SRI format SHA256 hashes
# Usage:
#   ./nix-generate-sha URL
#   Example: ./nix-generate-sha https://github.com/narugit/smctemp/archive/eebe38b4e27ca9a8b2caef0fda09694de5751874.tar.gz

set -e

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 URL"
  echo "  URL: URL to fetch and generate SHA256 hash in SRI format"
  echo "  Example: $0 https://github.com/narugit/smctemp/archive/eebe38b4e27ca9a8b2caef0fda09694de5751874.tar.gz"
  exit 1
fi

URL="$1"
echo "Generating SRI hash for $URL..."

# Get hash in base format and convert to SRI
nix-prefetch-url --unpack "$URL" 2>/dev/null | xargs nix hash to-sri --type sha256 --extra-experimental-features nix-command
