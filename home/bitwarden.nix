{ pkgs, ... }:

# Set EU server (one-time):
#
# ```console
# bw config server https://vault.bitwarden.eu
# ```
#
# Login via SSO:
#
# ```console
# bw login --sso
# ```
#
# Get API credentials: Settings -> Security -> Keys -> View API key
# Save OAuth 2.0 Client Credentials to password store:
#
# ```console
# echo "<client_id>" | pass insert -e vault.bitwarden.eu/<email>/client_id
# echo "<client_secret>" | pass insert -e vault.bitwarden.eu/<email>/client_secret
# ```
#
# Unlock vault and save session (since timeout is set to "never"):
#
# ```console
# bw unlock --raw | pass insert -e vault.bitwarden.eu/<email>/session
# ```
#
# Store BW_SESSION under envrc/secrets
#
# ```console
# pass edit envrc/secrets
# ```

{
  home.packages = [
    pkgs.bitwarden-cli
  ];
}
