#!/usr/bin/env bash

# Variables
AWS_SSO_ROLE=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    --role)
        AWS_SSO_ROLE="$2"
        shift
        shift
        ;;
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
done

# Check if all required arguments are provided
if [[ -z $AWS_SSO_ROLE ]]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 --role <value>"
    exit 1
fi

PROFILE=$(aws-sso | rg "${AWS_SSO_ROLE}" | fzf | awk '{print $7}')

aws-sso console --profile "${PROFILE}"
