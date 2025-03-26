#!/usr/bin/env bash

# Vault Authentication Script
#
# This script handles Vault authentication using OIDC method and stores the token
# securely using the 'pass' password manager.
#
# Usage:
#   eval $(vault-auth --address "https://vault.example.com" \
#                     --username "user@example.com" \
#                     --path "custom_oidc" \
#                     --role "custom_role")
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
while [[ $# -gt 0 ]]; do
    case $1 in
        --address|-a)
            VAULT_ADDR="$2"
            shift 2
            ;;
        --username|-u)
            VAULT_USER_EMAIL="$2"
            shift 2
            ;;
        --role|-r)
            VAULT_ROLE="$2"
            shift 2
            ;;
        --path|-p)
            VAULT_OIDC_PATH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Check required variables
[[ -n "$VAULT_ADDR" ]] || { echo "Error: VAULT_ADDR must be set via environment variable or --address flag" >&2; exit 1; }
[[ -n "$VAULT_USER_EMAIL" ]] || { echo "Error: VAULT_USER_EMAIL must be set via environment variable or --username flag" >&2; exit 1; }
[[ -n "$VAULT_OIDC_PATH" ]] || { echo "Error: VAULT_OIDC_PATH must be set via environment variable or --path flag" >&2; exit 1; }
[[ -n "$VAULT_ROLE" ]] || { echo "Error: VAULT_ROLE must be set via environment variable or --role flag" >&2; exit 1; }

# Function to get token from pass
fetch_token_from_pass() {
    if command -v pass >/dev/null 2>&1; then
        # Sanitize the path for pass
        local pass_path="vault/$(echo "$VAULT_ADDR" | sed 's|https://||')/$VAULT_USER_EMAIL/token"
        pass "$pass_path" 2>/dev/null
    else
        echo "Warning: 'pass' command not found. Cannot retrieve stored token." >&2
        return 1
    fi
}

# Function to check if the current token is valid
is_token_valid() {
    local token="$1"
    [[ -n "$token" ]] || return 1
    VAULT_TOKEN="$token" vault token lookup >/dev/null 2>&1
}

# Function to update token in pass
update_token_in_pass() {
    local token="$1"
    [[ -n "$token" ]] || { echo "Error: Cannot store empty token." >&2; return 1; }
    
    if command -v pass >/dev/null 2>&1; then
        # Sanitize the path for pass
        local pass_path="vault/$(echo "$VAULT_ADDR" | sed 's|https://||')/$VAULT_USER_EMAIL/token"
        echo "$token" | pass insert --echo --force "$pass_path"
    else
        echo "Warning: 'pass' command not found. Cannot store token." >&2
        return 1
    fi
}

# Try to fetch token from pass
VAULT_TOKEN=$(fetch_token_from_pass)

# If token is not in pass or expired, login to get a new one
if [[ -z "$VAULT_TOKEN" ]] || ! is_token_valid "$VAULT_TOKEN"; then
    echo "Fetching new token from Vault login..." >&2
    VAULT_TOKEN=$(vault login -method=oidc -path="$VAULT_OIDC_PATH" -token-only role="$VAULT_ROLE")
    
    echo "Token fetched successfully" >&2
    
    # Update the new token in pass
    if [[ -n "$VAULT_TOKEN" ]]; then
        echo "Updating token in pass..." >&2
        update_token_in_pass "$VAULT_TOKEN"
    fi
fi

# Output environment variables for eval to capture
printf 'export VAULT_ADDR="%s"\n' "$VAULT_ADDR"
printf 'export VAULT_TOKEN="%s"\n' "$VAULT_TOKEN" 
