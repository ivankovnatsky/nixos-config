{ ... }:
{
  # Common sops secrets declarations for home-manager
  # Import this in machines that use sops for these secrets

  sops.secrets.email = {
    key = "email";
  };

  sops.secrets.openai-api-key = {
    key = "openaiApiKey";
  };

  sops.secrets.anthropic-api-key = {
    key = "anthropicApiKey";
  };

  sops.secrets.google-cloud-project = {
    key = "googleCloudProject";
  };

  sops.secrets.github-token = {
    key = "githubToken";
  };

  sops.secrets.external-domain = {
    key = "externalDomain";
  };

  sops.secrets.audiobookshelf-api-token = {
    key = "audiobookshelf/apiToken";
  };

  sops.secrets.audiobookshelf-url = {
    key = "audiobookshelf/url";
  };

  sops.secrets.bitwarden-session = {
    key = "bitwardenSession";
  };

  sops.secrets.gh-mcp-token = {
    key = "ghMcpToken";
  };

  sops.secrets.uptime-kuma-username = {
    key = "uptimeKuma/username";
  };

  sops.secrets.uptime-kuma-password = {
    key = "uptimeKuma/password";
  };
}
