{ config, ... }:

let
  inherit (config.flags) miniIp;
in
{
  # Uptime Kuma declarative monitor management for a3
  # a3 hosts all Kuma monitors for the fleet: mini-local services via
  # config.flags.miniIp, a3-local services via 127.0.0.1, and the public
  # external-domain probe.
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
  sops.secrets.discord-webhook-kuma = {
    key = "discord/webhooks/monitoringKuma";
  };
  sops.secrets.postgres-monitoring-password = {
    key = "postgres/monitoring/password";
  };

  local.services.uptime-kuma-mgmt = {
    enable = true;
    notifications.enable = false;
    baseUrl = "http://127.0.0.1:3001";
    usernameFile = config.sops.secrets.uptime-kuma-username.path;
    passwordFile = config.sops.secrets.uptime-kuma-password.path;
    discordWebhookFile = config.sops.secrets.discord-webhook-kuma.path;
    externalDomainFile = config.sops.secrets.external-domain.path;
    postgresPasswordFile = config.sops.secrets.postgres-monitoring-password.path;

    monitors = [
      # ---- External / public probe ----
      {
        name = "external-domain";
        url = "https://forgejo.@EXTERNAL_DOMAIN@";
        interval = 60;
        description = "External domain health check (DNS + Caddy + TLS)";
      }

      # ---- a3-local services ----
      {
        name = "beszel-agent-a3";
        type = "tcp";
        url = "127.0.0.1:45876";
        interval = 60;
        description = "Beszel agent (a3)";
      }
      {
        name = "beszel-hub-a3";
        url = "http://127.0.0.1:8090";
        interval = 60;
        description = "Beszel monitoring hub (a3)";
      }
      {
        name = "caddy-http-a3";
        type = "tcp";
        url = "127.0.0.1:80";
        interval = 60;
        description = "Caddy HTTP reverse proxy (a3)";
      }
      {
        name = "caddy-https-a3";
        type = "tcp";
        url = "127.0.0.1:443";
        interval = 60;
        description = "Caddy HTTPS reverse proxy (a3)";
      }
      {
        name = "dnsmasq-a3";
        type = "dns";
        url = "example.com@127.0.0.1";
        interval = 60;
        description = "dnsmasq DNS resolver (a3)";
      }
      {
        name = "forgejo-a3";
        url = "http://127.0.0.1:3000";
        interval = 60;
        description = "Forgejo git server (a3)";
      }
      {
        name = "forgejo-ssh-a3";
        type = "tcp";
        url = "127.0.0.1:2222";
        interval = 60;
        description = "Forgejo SSH git access (a3)";
      }
      {
        name = "miniserve-a3";
        url = "http://127.0.0.1:8080";
        interval = 60;
        expectedStatus = 401;
        description = "Miniserve file server (a3, auth required)";
      }
      {
        name = "jellyfin-a3";
        url = "http://127.0.0.1:8096";
        interval = 60;
        expectedStatus = [
          "200-299"
          "302"
        ];
        maxredirects = 0;
        description = "Jellyfin media server (a3, redirects to /web)";
      }
      {
        name = "lidarr-a3";
        url = "http://127.0.0.1:8686";
        interval = 60;
        description = "Lidarr music manager (a3)";
      }
      {
        name = "navidrome-a3";
        url = "http://127.0.0.1:4533";
        interval = 60;
        description = "Navidrome music streaming server (a3)";
      }
      {
        name = "ollama-a3";
        url = "http://127.0.0.1:11434";
        interval = 60;
        description = "Ollama LLM API (a3, CUDA)";
      }
      {
        name = "openclaw-gateway-a3";
        url = "http://127.0.0.1:18789";
        interval = 60;
        description = "OpenClaw gateway (a3)";
      }
      {
        name = "open-webui-a3";
        url = "http://127.0.0.1:8091";
        interval = 60;
        description = "Open WebUI (a3)";
      }
      {
        name = "prowlarr-a3";
        url = "http://127.0.0.1:9696";
        interval = 60;
        description = "Prowlarr indexer manager (a3)";
      }
      {
        name = "radarr-a3";
        url = "http://127.0.0.1:7878";
        interval = 60;
        description = "Radarr movie manager (a3)";
      }
      {
        name = "sonarr-a3";
        url = "http://127.0.0.1:8989";
        interval = 60;
        description = "Sonarr TV manager (a3)";
      }
      {
        name = "stubby-a3";
        type = "tcp";
        url = "127.0.0.1:5453";
        interval = 60;
        description = "Stubby DoT resolver (a3, upstream for dnsmasq)";
      }
      {
        name = "syncthing-a3";
        url = "http://127.0.0.1:8384";
        interval = 60;
        description = "Syncthing file sync (a3)";
      }
      {
        name = "transmission-a3";
        url = "http://127.0.0.1:9091";
        interval = 60;
        expectedStatus = 401;
        description = "Transmission torrent client (a3, RPC auth required)";
      }
      {
        name = "uptime-kuma-a3";
        url = "http://127.0.0.1:3001";
        interval = 60;
        description = "Uptime Kuma self-probe (a3)";
      }

      # ---- mini-hosted services ----
      {
        name = "dnsmasq-mini";
        type = "dns";
        url = "example.com@${miniIp}";
        interval = 60;
        description = "dnsmasq DNS resolver (mini)";
      }
      {
        name = "smb-mini";
        type = "tcp";
        url = "${miniIp}:445";
        interval = 60;
        description = "macOS built-in SMB service (mini)";
      }
      {
        name = "ssh-mini";
        type = "tcp";
        url = "${miniIp}:22";
        interval = 60;
        description = "SSH service (mini)";
      }
      {
        name = "stubby-mini";
        type = "tcp";
        url = "${miniIp}:5453";
        interval = 60;
        description = "Stubby DoT resolver (mini, upstream for dnsmasq)";
      }
      {
        name = "syncthing-mini";
        url = "http://${miniIp}:8384";
        interval = 60;
        description = "Syncthing file sync (mini)";
      }
    ];
  };
}
