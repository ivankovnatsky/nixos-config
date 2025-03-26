#!/usr/bin/env fish

# Vault Authentication Script
#
# This script handles Vault authentication using OIDC method and stores the token
# securely using the 'pass' password manager.
#
# Usage:
#   eval (vault-auth-fish --address "https://vault.example.com" \
#                    --username "user@example.com" \
#                    --path "custom_oidc" \
#                    --role "custom_role")
#
# Required options:
#   --address  : Vault server URL
#   --username : User email for authentication
#   --path     : OIDC authentication path
#   --role     : Vault role to use
#
# The script will:
# 1. Check for existing valid token in pass
# 2. If no valid token exists, authenticate with Vault using OIDC
# 3. Store the new token in pass for future use
# 4. Export VAULT_TOKEN for use in current shell session

# Parse command line arguments
function parse_args
    argparse 'a/address=' 'u/username=' 'r/role=' 'p/path=' -- $argv
    or return 1

    if set -q _flag_address
        set -g vault_addr $_flag_address
    end

    if set -q _flag_username
        set -g vault_user_email $_flag_username
    end

    if set -q _flag_role
        set -g vault_role $_flag_role
    end

    if set -q _flag_path
        set -g vault_oidc_path $_flag_path
    end
end

# Parse arguments if any provided
parse_args $argv

# Check required variables
if not test -n "$vault_addr"
    echo "Error: vault_addr must be set via environment variable or --address flag" >&2
    exit 1
end

if not test -n "$vault_user_email"
    echo "Error: vault_user_email must be set via environment variable or --username flag" >&2
    exit 1
end

if not test -n "$vault_oidc_path"
    echo "Error: vault_oidc_path must be set via environment variable or --path flag" >&2
    exit 1
end

if not test -n "$vault_role"
    echo "Error: vault_role must be set via environment variable or --role flag" >&2
    exit 1
end

# Set AWS provider if needed
if test -n "$aws_profile"
    set -g aws_profile $aws_profile
end

# Function to get token from pass
function fetch_token_from_pass
    if type -q pass
        pass "$vault_addr/$vault_user_email/token" 2>/dev/null
    else
        echo "Warning: 'pass' command not found. Cannot retrieve stored token." >&2
        return 1
    end
end

# Function to check if the current token is valid
function is_token_valid
    if test -z "$argv[1]"
        return 1 # Empty token is invalid
    end

    if env VAULT_TOKEN=$argv[1] vault token lookup >/dev/null 2>&1
        return 0 # Token is valid
    else
        return 1 # Token is invalid
    end
end

# Function to update token in pass
function update_token_in_pass
    if test -z "$argv[1]"
        echo "Error: Cannot store empty token." >&2
        return 1
    end

    if type -q pass
        echo $argv[1] | pass insert --echo --force "$vault_addr/$vault_user_email/token"
    else
        echo "Warning: 'pass' command not found. Cannot store token." >&2
        return 1
    end
end

# Try to fetch token from pass
set -g vault_token (fetch_token_from_pass)

# If token is not in pass or expired, login to get a new one
if test -z "$vault_token" || ! is_token_valid $vault_token
    echo "Fetching new token from Vault login..." >&2
    set -g vault_token (vault login -method=oidc -path=$vault_oidc_path -token-only role=$vault_role)

    echo "Token fetched successfully" >&2

    # Update the new token in pass
    if test -n "$vault_token"
        echo "Updating token in pass..." >&2
        update_token_in_pass $vault_token
    end
end

# Output environment variables for eval to capture
echo "set -x VAULT_ADDR \"$vault_addr\""
echo "set -x VAULT_TOKEN \"$vault_token\""
