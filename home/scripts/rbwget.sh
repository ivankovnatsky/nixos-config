#!/usr/bin/env bash

# This script retrieves an item's field from Bitwarden using rbw,
# filters the results with ripgrep (rg), and selects one with fzf if there are multiple matches.
# The selected field is then copied to the clipboard with clipboard tool.

# Check if the required number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <name> <item>"
    exit 1
fi

# Define clipboard tool based on platform.
if [[ "$OSTYPE" == "darwin"* ]]; then
    clipboard="pbcopy"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    clipboard="xclip -selection clipboard"
else
    echo "Error: Unsupported platform."
    exit 1
fi

name="$1"
item="$2"

# Check if required commands are available
for cmd in rbw rg fzf $clipboard; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd not found. Please install $cmd and try again."
        exit 1
    fi
done

# Retrieve the specified item from Bitwarden and filter with rg
output=$(rbw ls --fields name,user | rg -i "$name")

# Check if any matching items were found
if [ -z "$output" ]; then
    echo "No matching items found."
    exit 1
fi

# Count the number of matches
count=$(echo "$output" | wc -l)

if [ "$count" -gt 1 ]; then
    # Select an item with fzf if there are multiple matches
    selected=$(echo "$output" | fzf)
else
    # Use the single match if there's only one
    selected="$output"
fi

# Extract the specified field and copy it to the clipboard
echo "$selected" | xargs -r rbw get --field "$item" | sed 's/^.*: //' | $clipboard

echo "The $item field of the selected item has been copied to the clipboard."
