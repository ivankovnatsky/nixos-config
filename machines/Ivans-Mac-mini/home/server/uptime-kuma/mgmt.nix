{ config, ... }:

{
  # Uptime Kuma declarative monitor management
  # Automatically syncs monitors and Discord notifications from Nix configuration on system activation
  #
  # Manual operations:
  # - List monitors: uptime-kuma-mgmt list --base-url $(cat ~/.config/sops-nix/secrets/uptime-kuma-base-url) --username $(cat ~/.config/sops-nix/secrets/uptime-kuma-username) --password $(cat ~/.config/sops-nix/secrets/uptime-kuma-password)
  # - Dry-run sync: Temporarily set enable = false and run manually with --dry-run
  #
  # Initial setup required:
  # 1. Access the Uptime Kuma URL (from sops secrets)
  # 2. Create admin account matching credentials in sops secrets
  # 3. Monitors and Discord notifications will auto-sync on next rebuild

  sops.secrets.discord-webhook-kuma = {
    key = "discord/webhooks/monitoringKuma";
  };
  sops.secrets.postgres-monitoring-password = {
    key = "postgres/monitoring/password";
  };

  local.services.uptime-kuma-mgmt = {
    enable = true;
    notifications.enable = false;
    baseUrl = "http://${config.flags.machineLocalAddress}:3001";
    usernameFile = config.sops.secrets.uptime-kuma-username.path;
    passwordFile = config.sops.secrets.uptime-kuma-password.path;
    discordWebhookFile = config.sops.secrets.discord-webhook-kuma.path;
    externalDomainFile = config.sops.secrets.external-domain.path;
    postgresPasswordFile = config.sops.secrets.postgres-monitoring-password.path;

    monitors = [
      {
        name = "external-domain";
        url = "https://beszel.@EXTERNAL_DOMAIN@";
        interval = 60;
        description = "External domain health check (DNS + Caddy + TLS)";
      }
      {
        name = "prowlarr";
        url = "http://${config.flags.machineLocalAddress}:9696";
        description = "Prowlarr indexer manager";
      }
      {
        name = "radarr";
        url = "http://${config.flags.machineLocalAddress}:7878";
        description = "Radarr movie manager";
      }
      {
        name = "lidarr";
        url = "http://${config.flags.machineLocalAddress}:8686";
        description = "Lidarr music manager";
      }
      {
        name = "sonarr";
        url = "http://${config.flags.machineLocalAddress}:8989";
        description = "Sonarr TV manager";
      }
      {
        name = "transmission";
        url = "http://${config.flags.machineLocalAddress}:9091";
        expectedStatus = 401;
        description = "Transmission torrent client (RPC auth required)";
      }
      {
        name = "jellyfin";
        url = "http://${config.flags.machineLocalAddress}:8096";
        description = "Jellyfin media server";
      }
      {
        name = "stash";
        url = "http://${config.flags.a3Ip}:9999";
        expectedStatus = 302;
        maxredirects = 0;
        description = "Stash media organizer (redirects to /login)";
      }
      {
        name = "media";
        url = "http://${config.flags.machineLocalAddress}:9998";
        description = "Stash media organizer (general)";
      }
      {
        name = "navidrome";
        url = "http://${config.flags.machineLocalAddress}:4533";
        description = "Navidrome music streaming server";
      }
      {
        name = "syncthing";
        url = "http://${config.flags.machineLocalAddress}:8384";
        description = "Syncthing file sync";
      }
      {
        name = "beszel";
        url = "http://${config.flags.machineLocalAddress}:8091";
        description = "Beszel monitoring hub";
      }
      {
        name = "miniserve";
        url = "http://${config.flags.machineLocalAddress}:8080";
        expectedStatus = 401;
        description = "Miniserve file server (auth required)";
      }
      {
        name = "podservice";
        url = "http://${config.flags.machineLocalAddress}:8083";
        description = "YouTube to Podcast service";
      }
      {
        name = "textcast";
        url = "http://${config.flags.machineLocalAddress}:8084";
        description = "Article to audiobook service";
      }
      {
        name = "youtube";
        url = "http://${config.flags.machineLocalAddress}:8085";
        description = "YouTube video downloader";
      }
      {
        name = "uptime-kuma";
        url = "http://${config.flags.machineLocalAddress}:3001";
        description = "Uptime Kuma monitoring";
      }
      {
        name = "ollama";
        url = "http://${config.flags.machineLocalAddress}:11434";
        description = "Ollama LLM API";
      }
      {
        name = "openwebui";
        url = "http://${config.flags.machineLocalAddress}:8090";
        description = "Open WebUI";
      }
      {
        name = "openclaw-gateway";
        url = "http://${config.flags.machineLocalAddress}:18789";
        interval = 60;
        description = "OpenClaw gateway";
      }
      {
        name = "mailpit";
        url = "http://${config.flags.machineLocalAddress}:8025";
        description = "Mailpit email testing UI";
      }
      {
        name = "forgejo";
        url = "http://${config.flags.machineLocalAddress}:3300";
        description = "Forgejo git server";
      }
      {
        name = "forgejo-ssh";
        type = "tcp";
        url = "${config.flags.machineLocalAddress}:2222";
        interval = 60;
        description = "Forgejo SSH git access";
      }
      {
        name = "dnsmasq";
        type = "dns";
        url = "example.com@${config.flags.machineLocalAddress}";
        interval = 60;
        description = "dnsmasq DNS resolver";
      }
      {
        name = "stubby";
        type = "tcp";
        url = "${config.flags.machineLocalAddress}:5453";
        interval = 60;
        description = "Stubby DoT resolver (upstream for dnsmasq)";
      }
      {
        name = "caddy-http";
        type = "tcp";
        url = "${config.flags.machineLocalAddress}:80";
        interval = 60;
        description = "Caddy HTTP reverse proxy";
      }
      {
        name = "caddy-https";
        type = "tcp";
        url = "${config.flags.machineLocalAddress}:443";
        interval = 60;
        description = "Caddy HTTPS reverse proxy";
      }
      {
        name = "ssh";
        type = "tcp";
        url = "${config.flags.machineLocalAddress}:22";
        interval = 60;
        description = "SSH service";
      }
      {
        name = "smb";
        type = "tcp";
        url = "${config.flags.machineLocalAddress}:445";
        interval = 60;
        description = "macOS built-in SMB service";
      }
    ];
  };
}
