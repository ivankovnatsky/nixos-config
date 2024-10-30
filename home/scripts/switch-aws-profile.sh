#!/usr/bin/env bash

# Exit on error, but don't print commands
set -e

# Function to get AWS profiles from both config and credentials files
get_aws_profiles() {
    local config_file="$HOME/.aws/config"
    local credentials_file="$HOME/.aws/credentials"
    local profiles=()

    # Get profiles from config file
    if [[ -f "$config_file" ]]; then
        while IFS= read -r line; do
            if [[ $line =~ ^\[profile[[:space:]]+([^\]]+)\] ]]; then
                profiles+=("${BASH_REMATCH[1]}")
            elif [[ $line =~ ^\[([^\]]+)\] ]] && [[ "${BASH_REMATCH[1]}" != "default" ]]; then
                profiles+=("${BASH_REMATCH[1]}")
            fi
        done < "$config_file"
    fi

    # Get profiles from credentials file
    if [[ -f "$credentials_file" ]]; then
        while IFS= read -r line; do
            if [[ $line =~ ^\[([^\]]+)\] ]] && [[ "${BASH_REMATCH[1]}" != "default" ]]; then
                profiles+=("${BASH_REMATCH[1]}")
            fi
        done < "$credentials_file"
    fi

    # Remove duplicates and sort
    printf "%s\n" "${profiles[@]}" | sort -u
}

# Check for fzf
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is not installed" >&2
    exit 1
fi

# Get profiles
profiles=$(get_aws_profiles)

if [[ -z "$profiles" ]]; then
    echo "Error: No AWS profiles found" >&2
    exit 1
fi

# Use fzf to select a profile
if selected_profile=$(echo "$profiles" | fzf --height 40% --border --prompt="Select AWS Profile > "); then
    echo "export AWS_PROFILE='$selected_profile'"
fi
