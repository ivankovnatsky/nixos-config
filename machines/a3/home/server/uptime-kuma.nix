{ config, ... }:

{
  # Uptime Kuma declarative monitor management for a3
  # Monitors a3-local services that mini's Kuma can't reach due to macOS
  # Local Network Privacy gating LaunchAgent connects to RFC1918 unicast.
  #
  # Initial setup required:
  # 1. Access http://a3:3001
  # 2. Create admin account matching credentials in sops secrets
  # 3. Monitors auto-sync on next home-manager activation

  sops.secrets.uptime-kuma-username = {
    key = "uptimeKuma/a3/username";
  };
  sops.secrets.uptime-kuma-password = {
    key = "uptimeKuma/a3/password";
  };

  local.services.uptime-kuma-mgmt = {
    enable = true;
    notifications.enable = false;
    baseUrl = "http://127.0.0.1:3001";
    usernameFile = config.sops.secrets.uptime-kuma-username.path;
    passwordFile = config.sops.secrets.uptime-kuma-password.path;

    monitors = [
      {
        name = "stash";
        url = "http://127.0.0.1:9999";
        expectedStatus = [
          "200-299"
          "302"
        ];
        maxredirects = 0;
        description = "Stash media organizer (redirects to /login)";
      }
      {
        name = "beszel-hub";
        url = "http://127.0.0.1:8090";
        description = "Beszel monitoring hub";
      }
      {
        name = "beszel-agent";
        type = "tcp";
        url = "127.0.0.1:45876";
        interval = 60;
        description = "Beszel agent (local)";
      }
    ];
  };
}
