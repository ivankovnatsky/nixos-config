#!/usr/bin/env bash

# Under fish shell:
# ```console
# eval (switch-aws-profile.sh)             # interactive mode
# eval (switch-aws-profile.sh profile-name) # direct mode
# ```

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

# Get the profile name from the argument, if provided
profile_name_arg="$1"

# Get profiles
profiles=$(get_aws_profiles)

if [[ -z "$profiles" ]]; then
    echo "Error: No AWS profiles found" >&2
    exit 1
fi

# Check if a profile name was provided as an argument
if [[ -n "$profile_name_arg" ]]; then
    if echo "$profiles" | grep -q "^$profile_name_arg$"; then
        selected_profile="$profile_name_arg"
    else
        echo "Error: Profile '$profile_name_arg' not found" >&2
        exit 1
    fi
else
    # Use fzf to select a profile
    selected_profile=$(echo "$profiles" | fzf --height 40% --border --prompt="Select AWS Profile > ")
fi

# Export the selected profile if one was selected
if [[ -n "$selected_profile" ]]; then
    echo "set -gx AWS_PROFILE '$selected_profile'"
fi
