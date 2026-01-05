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
  --address | -a)
    VAULT_ADDR="$2"
    shift 2
    ;;
  --username | -u)
    VAULT_USER_EMAIL="$2"
    shift 2
    ;;
  --role | -r)
    VAULT_ROLE="$2"
    shift 2
    ;;
  --path | -p)
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
[[ -n "$VAULT_ADDR" ]] || {
  echo "Error: VAULT_ADDR must be set via environment variable or --address flag" >&2
  exit 1
}
[[ -n "$VAULT_USER_EMAIL" ]] || {
  echo "Error: VAULT_USER_EMAIL must be set via environment variable or --username flag" >&2
  exit 1
}
[[ -n "$VAULT_OIDC_PATH" ]] || {
  echo "Error: VAULT_OIDC_PATH must be set via environment variable or --path flag" >&2
  exit 1
}
[[ -n "$VAULT_ROLE" ]] || {
  echo "Error: VAULT_ROLE must be set via environment variable or --role flag" >&2
  exit 1
}

# Function to get token from pass
fetch_token_from_pass() {
  if command -v pass >/dev/null 2>&1; then
    # Use the correct path format for pass
    local pass_path
    pass_path="${VAULT_ADDR#https://}/$VAULT_USER_EMAIL/token"
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

  # Check if token is valid
  if VAULT_ADDR="$VAULT_ADDR" VAULT_TOKEN="$token" vault token lookup >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Function to update token in pass
update_token_in_pass() {
  local token="$1"
  [[ -n "$token" ]] || {
    echo "Error: Cannot store empty token." >&2
    return 1
  }

  if command -v pass >/dev/null 2>&1; then
    # Use the correct path format for pass
    local pass_path
    pass_path="${VAULT_ADDR#https://}/$VAULT_USER_EMAIL/token"

    echo "Updating $pass_path..." >&2
    # Redirect all output to avoid fish shell issues with git commit messages
    echo "$token" | pass insert --echo --force "$pass_path" >/dev/null 2>&1
    return $?
  else
    echo "Warning: 'pass' command not found. Cannot store token." >&2
    return 1
  fi
}

# Function to patch VAULT_TOKEN in envrc/secrets (preserves other secrets)
patch_envrc_secrets() {
  local token="$1"
  local envrc_path="envrc/secrets"

  [[ -n "$token" ]] || {
    echo "Error: Cannot patch with empty token." >&2
    return 1
  }

  if ! command -v pass >/dev/null 2>&1; then
    echo "Warning: 'pass' command not found. Cannot patch envrc/secrets." >&2
    return 1
  fi

  # Check if envrc/secrets exists
  if ! pass show "$envrc_path" >/dev/null 2>&1; then
    echo "Warning: $envrc_path not found in pass. Skipping patch." >&2
    return 0
  fi

  # Use temp file for safe multiline handling
  local tmp_file
  tmp_file=$(mktemp)
  chmod 600 "$tmp_file"
  trap "rm -f '$tmp_file'" RETURN

  # Read current contents to temp file
  pass show "$envrc_path" >"$tmp_file" 2>/dev/null

  # Check if token is already up to date
  local current_token
  current_token=$(grep "^export VAULT_TOKEN=" "$tmp_file" | sed 's/^export VAULT_TOKEN="\(.*\)"$/\1/')
  if [[ "$current_token" == "$token" ]]; then
    echo "envrc/secrets already up to date" >&2
    return 0
  fi

  # Token differs, update it
  if grep -q "^export VAULT_TOKEN=" "$tmp_file"; then
    echo "Updating VAULT_TOKEN in envrc/secrets..." >&2
    sed -i '' "s|^export VAULT_TOKEN=.*|export VAULT_TOKEN=\"$token\"|" "$tmp_file"
  else
    echo "Adding VAULT_TOKEN to envrc/secrets..." >&2
    printf 'export VAULT_TOKEN="%s"\n' "$token" >>"$tmp_file"
  fi

  # Write back to pass
  pass insert --echo --force "$envrc_path" <"$tmp_file" >/dev/null 2>&1
  return $?
}

# Try to fetch token from pass
VAULT_TOKEN=$(fetch_token_from_pass)

# Debug output (commented out for production)
# echo "Debug: Retrieved token from pass: ${VAULT_TOKEN:0:5}..." >&2

# If token is not in pass or expired, login to get a new one
if [[ -z "$VAULT_TOKEN" ]] || ! is_token_valid "$VAULT_TOKEN"; then
  echo "Fetching new token from Vault login..." >&2

  # Export VAULT_ADDR to environment before calling vault login
  export VAULT_ADDR="$VAULT_ADDR"

  VAULT_TOKEN=$(VAULT_ADDR="$VAULT_ADDR" vault login -method=oidc -path="$VAULT_OIDC_PATH" -token-only role="$VAULT_ROLE")

  if [[ -n "$VAULT_TOKEN" ]]; then
    echo "Token fetched successfully" >&2
    update_token_in_pass "$VAULT_TOKEN"
    patch_envrc_secrets "$VAULT_TOKEN"
  else
    echo "Failed to fetch token from Vault" >&2
    exit 1
  fi
else
  echo "Using existing valid token" >&2
  # Sync envrc/secrets in case it's out of date
  patch_envrc_secrets "$VAULT_TOKEN"
fi

# Create a temporary file for the output
TMP_FILE=$(mktemp)
chmod 600 "$TMP_FILE"

# Determine if we're being called from fish shell
if [[ "$FISH_VERSION" ]] || [[ "$SHELL" == *"fish"* ]]; then
  # Fish shell syntax
  echo "set -gx VAULT_ADDR \"$VAULT_ADDR\";" >"$TMP_FILE"
  echo "set -gx VAULT_TOKEN \"$VAULT_TOKEN\";" >>"$TMP_FILE"
else
  # Bash/zsh syntax
  echo "export VAULT_ADDR=\"$VAULT_ADDR\"" >"$TMP_FILE"
  echo "export VAULT_TOKEN=\"$VAULT_TOKEN\"" >>"$TMP_FILE"
fi

# Output the file content
cat "$TMP_FILE"

# Clean up
rm -f "$TMP_FILE"
