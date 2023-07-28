#!/usr/bin/env bash

# Variables
AWS_SSO_ROLE=""
AWS_ACCOUNT_ID=""

# Help function
display_help() {
    echo "Usage: $0 --role <value> [--account <value>]"
    exit 1
}

# Check if all required arguments are provided
if [[ $# -eq 0 ]]; then
    echo "Error: Missing required arguments."
    display_help
fi

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    --role)
        AWS_SSO_ROLE="$2"
        shift 2
        ;;
    --account)
        AWS_ACCOUNT_ID="$2"
        shift 2
        ;;
    --help)
        display_help
        ;;
    *)
        echo "Unknown argument: $1"
        display_help
        ;;
    esac
done

# Check if the required argument is provided
if [[ -z $AWS_SSO_ROLE ]]; then
    echo "Error: Missing required arguments."
    display_help
fi

# Function to select an AWS account using fzf
select_aws_account() {
    local role="$1"
    local account_id=""

    if [[ -z $AWS_ACCOUNT_ID ]]; then
        account_id=$(aws-sso | rg "$role" | fzf | awk '{print $7}')
    else
        account_id=$(aws-sso | rg "$role" | rg "$AWS_ACCOUNT_ID" | awk '{print $7}')
    fi

    echo "$account_id"
}

# Select AWS account
PROFILE=$(select_aws_account "$AWS_SSO_ROLE")

# Launch AWS SSO console
aws-sso console --profile "$PROFILE"
