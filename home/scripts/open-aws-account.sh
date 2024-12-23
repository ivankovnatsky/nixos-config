#!/usr/bin/env bash

# Constants
APP_NAME="Google Chrome"
CHROME_BROWSER_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CHROME_PREFS_PATH="$HOME/Library/Application Support/Google/Chrome"

# Variables
BROWSER="chrome"
AWS_SSO=""
AWS_ROLE_NAME=""
AWS_ACCOUNT_ID=""
AWS_ACCOUNT_ALIAS=""
AWS_PROFILE=""

# Help function
display_help() {
    echo "Usage: $0 --browser <chrome|firefox> --sso <value> [options]"
    echo
    echo "Options:"
    echo "  --browser        Browser to use (chrome or firefox)"
    echo "  --sso            SSO instance name"
    echo "  --role-name      Role name (will show filtered fzf dialog)"
    echo "  --account-id     AWS Account ID (exact match)"
    echo "  --account-alias  AWS Account Alias (exact match)"
    echo "  --profile        AWS Profile name (exact match)"
    echo
    echo "Example: $0 --sso Default --role-name AdministratorAccess"
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
    --role-name)
        AWS_ROLE_NAME="$2"
        shift 2
        ;;
    --account-id)
        AWS_ACCOUNT_ID="$2"
        shift 2
        ;;
    --account-alias)
        AWS_ACCOUNT_ALIAS="$2"
        shift 2
        ;;
    --profile)
        AWS_PROFILE="$2"
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
    echo "Error: Missing required --sso argument."
    display_help
fi

# Current aws-sso output:
#
# 00000000000001 | AccountAlias | AWSIamRoleName | AccountAlias:AWSIamRoleName | Expired
# AccountIdPad | AccountAlias | RoleName | Profile | Expires
extract_role_name() {
    cut -d '|' -f 4 | tr -d ' '
}

# Function to select an AWS account using fzf
select_aws_account() {
    local role="$1"
    local account_id="$AWS_ACCOUNT_ID"
    local account_alias="$AWS_ACCOUNT_ALIAS"
    local profile="$AWS_PROFILE"
    local result=""

    # If exact profile is provided, use it directly
    if [[ -n $profile ]]; then
        result=$(aws-sso --config ~/.aws-sso/"$BROWSER".yaml --sso "$AWS_SSO" | \
            rg '^[0-9]+' | \
            rg "$profile" | \
            extract_role_name)
        echo "$result"
        return
    fi

    # Build filter for account identifiers
    local filter=""
    if [[ -n $account_id ]]; then
        filter="rg '$account_id'"
    fi
    if [[ -n $account_alias ]]; then
        if [[ -n $filter ]]; then
            filter="$filter | rg '$account_alias'"
        else
            filter="rg '$account_alias'"
        fi
    fi

    # If we have account identifiers and role name, use exact match
    if [[ (-n $account_id || -n $account_alias) && -n $role ]]; then
        result=$(aws-sso --config ~/.aws-sso/"$BROWSER".yaml --sso "$AWS_SSO" | \
            rg '^[0-9]+' | \
            eval "$filter" | \
            rg "$role" | \
            extract_role_name)
    # If we have only account identifiers, show filtered fzf
    elif [[ -n $account_id || -n $account_alias ]]; then
        result=$(aws-sso --config ~/.aws-sso/"$BROWSER".yaml --sso "$AWS_SSO" | \
            rg '^[0-9]+' | \
            eval "$filter" | \
            fzf | \
            extract_role_name)
    # If we have only role name, show filtered fzf
    elif [[ -n $role ]]; then
        result=$(aws-sso --config ~/.aws-sso/"$BROWSER".yaml --sso "$AWS_SSO" | \
            rg '^[0-9]+' | \
            rg "$role" | \
            fzf | \
            extract_role_name)
    # Otherwise show full fzf
    else
        result=$(aws-sso --config ~/.aws-sso/"$BROWSER".yaml --sso "$AWS_SSO" | \
            rg '^[0-9]+' | \
            fzf | \
            extract_role_name)
    fi

    echo "$result"
}

# Function to verify if profile exists
verify_profile() {
    local profile="$1"
    aws-sso --config ~/.aws-sso/"$BROWSER".yaml --sso "$AWS_SSO" | rg -q "$profile"
}

# Select AWS account
if [[ -n $AWS_PROFILE ]]; then
    if ! verify_profile "$AWS_PROFILE"; then
        echo "Error: Profile '$AWS_PROFILE' not found in aws-sso output"
        exit 1
    fi
    PROFILE=$AWS_PROFILE
elif [[ (-n $AWS_ACCOUNT_ALIAS || -n $AWS_ACCOUNT_ID) && -n $AWS_ROLE_NAME ]]; then
    PROFILE=$(get_profile "$AWS_ACCOUNT_ALIAS" "$AWS_ROLE_NAME" "")
else
    PROFILE=$(select_aws_account "$AWS_ROLE_NAME")
fi

# Exit early if no profile was selected
if [[ -z $PROFILE ]]; then
    echo "No account selected or profile not found, exiting."
    exit 1
fi

init_chrome_preferences() {
    mkdir -p "$CHROME_PREFS_PATH/$PROFILE/"
    cat <<EOF > "$CHROME_PREFS_PATH/$PROFILE/Preferences"
{
  "profile": {
    "name": "$PROFILE"
  }
}
EOF
}

# Launch AWS SSO console
if [[ "$BROWSER" == "chrome" ]]; then
    init_chrome_preferences

    if ! URL=$(aws-sso console --config ~/.aws-sso/"$BROWSER".yaml --browser "$CHROME_BROWSER_PATH" \
        --sso "$AWS_SSO" --profile "$PROFILE" 2>&1); then
        echo "Error: Failed to get AWS console URL"
        echo "$URL"
        exit 1
    fi
    open --new -a "$APP_NAME" --args --profile-directory="$PROFILE" "$URL"
else
    aws-sso console --config ~/.aws-sso/"$BROWSER".yaml --sso "$AWS_SSO" --profile "$PROFILE"
fi
