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
        url = "https://stash.@EXTERNAL_DOMAIN@";
        interval = 60;
        description = "External domain health check (DNS + Caddy + TLS)";
      }

      # ---- a3-local services ----
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

      # ---- mini-hosted services ----
      {
        name = "prowlarr";
        url = "http://${miniIp}:9696";
        description = "Prowlarr indexer manager";
      }
      {
        name = "radarr";
        url = "http://${miniIp}:7878";
        description = "Radarr movie manager";
      }
      {
        name = "lidarr";
        url = "http://${miniIp}:8686";
        description = "Lidarr music manager";
      }
      {
        name = "sonarr";
        url = "http://${miniIp}:8989";
        description = "Sonarr TV manager";
      }
      {
        name = "transmission";
        url = "http://${miniIp}:9091";
        expectedStatus = 401;
        description = "Transmission torrent client (RPC auth required)";
      }
      {
        name = "jellyfin";
        url = "http://${miniIp}:8096";
        description = "Jellyfin media server";
      }
      {
        name = "media";
        url = "http://${miniIp}:9998";
        description = "Stash media organizer (general)";
      }
      {
        name = "navidrome";
        url = "http://${miniIp}:4533";
        description = "Navidrome music streaming server";
      }
      {
        name = "syncthing";
        url = "http://${miniIp}:8384";
        description = "Syncthing file sync";
      }
      {
        name = "miniserve";
        url = "http://${miniIp}:8080";
        expectedStatus = 401;
        description = "Miniserve file server (auth required)";
      }
      {
        name = "podservice";
        url = "http://${miniIp}:8083";
        description = "YouTube to Podcast service";
      }
      {
        name = "textcast";
        url = "http://${miniIp}:8084";
        description = "Article to audiobook service";
      }
      {
        name = "youtube";
        url = "http://${miniIp}:8085";
        description = "YouTube video downloader";
      }
      {
        name = "ollama";
        url = "http://${miniIp}:11434";
        description = "Ollama LLM API";
      }
      {
        name = "openwebui";
        url = "http://${miniIp}:8090";
        description = "Open WebUI";
      }
      {
        name = "openclaw-gateway";
        url = "http://${miniIp}:18789";
        interval = 60;
        description = "OpenClaw gateway";
      }
      {
        name = "mailpit";
        url = "http://${miniIp}:8025";
        description = "Mailpit email testing UI";
      }
      {
        name = "forgejo";
        url = "http://${miniIp}:3300";
        description = "Forgejo git server";
      }
      {
        name = "forgejo-ssh";
        type = "tcp";
        url = "${miniIp}:2222";
        interval = 60;
        description = "Forgejo SSH git access";
      }
      {
        name = "dnsmasq";
        type = "dns";
        url = "example.com@${miniIp}";
        interval = 60;
        description = "dnsmasq DNS resolver";
      }
      {
        name = "stubby";
        type = "tcp";
        url = "${miniIp}:5453";
        interval = 60;
        description = "Stubby DoT resolver (upstream for dnsmasq)";
      }
      {
        name = "caddy-http";
        type = "tcp";
        url = "${miniIp}:80";
        interval = 60;
        description = "Caddy HTTP reverse proxy";
      }
      {
        name = "caddy-https";
        type = "tcp";
        url = "${miniIp}:443";
        interval = 60;
        description = "Caddy HTTPS reverse proxy";
      }
      {
        name = "ssh";
        type = "tcp";
        url = "${miniIp}:22";
        interval = 60;
        description = "SSH service";
      }
      {
        name = "smb";
        type = "tcp";
        url = "${miniIp}:445";
        interval = 60;
        description = "macOS built-in SMB service";
      }
    ];
  };
}
