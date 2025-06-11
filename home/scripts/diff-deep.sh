#!/usr/bin/env bash

set -euo pipefail

# diff-deep.sh - Simple recursive directory comparison
# Usage: diff-deep.sh <dir1> <dir2>

if [ $# -ne 2 ]; then
    echo "Usage: $(basename "$0") <dir1> <dir2>"
    echo "Recursively compare two directories using diff"
    exit 1
fi

DIR1="$1"
DIR2="$2"

# Check if directories exist
if [ ! -d "$DIR1" ]; then
    echo "Error: Directory '$DIR1' does not exist" >&2
    exit 1
fi

if [ ! -d "$DIR2" ]; then
    echo "Error: Directory '$DIR2' does not exist" >&2
    exit 1
fi

# Use diff with recursive option
diff -r "$DIR1" "$DIR2"
