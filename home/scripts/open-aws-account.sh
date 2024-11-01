#!/usr/bin/env bash

# Constans
APP_NAME="Google Chrome"
CHROME_BROWSER_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Variables
BROWSER="firefox"
AWS_SSO=""
AWS_SSO_ROLE=""
AWS_ACCOUNT_ID=""

# Help function
display_help() {
    echo "Usage: $0 --browser --sso <value> --role <value> [--account <value>]"
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
    --browser)
        BROWSER="$2"
        shift 2
        ;;
    --sso)
        AWS_SSO="$2"
        shift 2
        ;;
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

if [[ $BROWSER != "firefox" && $BROWSER != "chrome" ]]; then
    echo "Error: Wrong browser selected, use 'firefox' or 'chrome' only."
    display_help
fi

# Check if the required argument is provided
if [[ -z $AWS_SSO ]]; then
    echo "Error: Missing required arguments."
    display_help
fi

# Current aws-sso output:
#
# 00000000000001 | AccountAlias | AWSIamRoleName | AccountAlias:AWSIamRoleName | Expired
extract_role_name() {
    awk '{print $8}'
}

# Function to select an AWS account using fzf
select_aws_account() {
    local role="$1"
    local account_id=""

    if [[ -z $AWS_ACCOUNT_ID ]]; then
        if [[ -z $role ]]; then
            account_id=$(aws-sso --sso "$AWS_SSO" | rg '^[0-9]+' | fzf | extract_role_name)
        else
            account_id=$(aws-sso --sso "$AWS_SSO" | rg '^[0-9]+' | rg "$role" | fzf | extract_role_name)
        fi
    else
        account_id=$(aws-sso --sso "$AWS_SSO" | rg '^[0-9]+' | rg "$role" | rg "$AWS_ACCOUNT_ID" | extract_role_name)
    fi

    echo "$account_id"
}

# Select AWS account
if [[ -z $AWS_SSO_ROLE ]]; then
    PROFILE=$(select_aws_account)
else
    PROFILE=$(select_aws_account "$AWS_SSO_ROLE")
fi

# Launch AWS SSO console
if [[ "$BROWSER" == "chrome" ]]; then
    # https://github.com/synfinatic/aws-sso-cli/blob/main/docs/config.md#authurlaction--browser--urlaction--urlexeccommand
    URL=$(aws-sso console --config ~/.aws-sso/chrome.yaml --browser "$CHROME_BROWSER_PATH" --sso "$AWS_SSO" --profile "$PROFILE" 2>&1)
    open --new -a "$APP_NAME" --args --profile-directory="$PROFILE" "$URL"
else
    aws-sso console --sso "$AWS_SSO" --profile "$PROFILE"
fi
