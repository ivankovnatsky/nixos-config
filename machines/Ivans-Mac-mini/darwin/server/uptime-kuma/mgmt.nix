{ config, ... }:

{
  # Uptime Kuma declarative monitor management
  # Automatically syncs monitors and Discord notifications from Nix configuration on system activation
  #
  # Manual operations:
  # - List monitors: uptime-kuma-mgmt list --base-url $(cat /run/secrets/uptime-kuma-base-url) --username $(cat /run/secrets/uptime-kuma-username) --password $(cat /run/secrets/uptime-kuma-password)
  # - Dry-run sync: Temporarily set enable = false and run manually with --dry-run
  #
  # Initial setup required:
  # 1. Access the Uptime Kuma URL (from /run/secrets/uptime-kuma-base-url)
  # 2. Create admin account matching credentials in sops secrets
  # 3. Monitors and Discord notifications will auto-sync on next rebuild

  # Sops secrets for Uptime Kuma management
  sops.secrets.uptime-kuma-username = {
    key = "uptimeKuma/username";
    owner = "ivan";
  };
  sops.secrets.uptime-kuma-password = {
    key = "uptimeKuma/password";
    owner = "ivan";
  };
  sops.secrets.discord-webhook = {
    key = "discordWebHook";
    owner = "ivan";
  };
  sops.secrets.postgres-monitoring-password = {
    key = "postgres/monitoring/password";
    owner = "ivan";
  };

  local.services.uptime-kuma-mgmt = {
    enable = true;
    # Connect to local instance using miniIp (matches service binding)
    baseUrl = "http://${config.flags.miniIp}:3001";
    usernameFile = config.sops.secrets.uptime-kuma-username.path;
    passwordFile = config.sops.secrets.uptime-kuma-password.path;
    discordWebhookFile = config.sops.secrets.discord-webhook.path;

    monitors = [
      # External Domain Health Check
      # Single check to verify DNS + Caddy + TLS chain works end-to-end
      {
        name = "external-domain";
        url = "https://beszel.@EXTERNAL_DOMAIN@";
        interval = 60;
        description = "External domain health check (DNS + Caddy + TLS)";
      }

      # Media Stack - Local HTTP monitoring
      {
        name = "prowlarr";
        url = "http://${config.flags.miniIp}:9696";
        description = "Prowlarr indexer manager";
      }
      {
        name = "radarr";
        url = "http://${config.flags.miniIp}:7878";
        description = "Radarr movie manager";
      }
      {
        name = "sonarr";
        url = "http://${config.flags.miniIp}:8989";
        description = "Sonarr TV manager";
      }
      {
        name = "transmission";
        url = "http://${config.flags.miniIp}:9091";
        expectedStatus = 401;
        description = "Transmission torrent client (RPC auth required)";
      }
      {
        name = "jellyfin";
        url = "http://${config.flags.miniIp}:8096";
        description = "Jellyfin media server";
      }
      {
        name = "stash";
        url = "http://${config.flags.miniIp}:9999";
        description = "Stash media organizer";
      }
      {
        name = "media";
        url = "http://${config.flags.miniIp}:9998";
        description = "Stash media organizer (general)";
      }
      {
        name = "audiobookshelf";
        url = "http://${config.flags.miniIp}:8000";
        description = "Audiobookshelf audiobook/podcast server";
      }

      # Infrastructure Services - Local HTTP monitoring
      {
        name = "syncthing";
        url = "http://${config.flags.miniIp}:8384";
        description = "Syncthing file sync";
      }
      {
        name = "beszel";
        url = "http://${config.flags.miniIp}:8091";
        description = "Beszel monitoring hub";
      }
      {
        name = "miniserve";
        url = "http://${config.flags.miniIp}:8080";
        expectedStatus = 401;
        description = "Miniserve file server (auth required)";
      }
      {
        name = "bin";
        url = "http://${config.flags.miniIp}:8820";
        description = "Pastebin service";
      }
      {
        name = "podservice";
        url = "http://${config.flags.miniIp}:8083";
        description = "YouTube to Podcast service";
      }
      {
        name = "textcast";
        url = "http://${config.flags.miniIp}:8084";
        description = "Article to audiobook service";
      }
      {
        name = "matrix";
        url = "http://${config.flags.miniIp}:8009";
        interval = 30;
        description = "Matrix Synapse server (critical)";
      }
      {
        name = "uptime-kuma";
        url = "http://${config.flags.miniIp}:3001";
        description = "Uptime Kuma monitoring";
      }
      {
        name = "doh";
        url = "http://${config.flags.miniIp}:8053/dns-query?dns=AAABAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB";
        expectedStatus = 200;
        description = "DNS over HTTPS service";
      }
      {
        name = "ollama";
        url = "http://${config.flags.miniIp}:11434";
        description = "Ollama LLM API";
      }
      {
        name = "openwebui";
        url = "http://${config.flags.miniIp}:8090";
        description = "Open WebUI";
      }

      # Matrix Bridges (TCP port monitoring - localhost only)
      {
        name = "mautrix-whatsapp";
        type = "tcp";
        url = "127.0.0.1:29321";
        interval = 60;
        description = "WhatsApp bridge appservice port";
      }
      {
        name = "mautrix-discord";
        type = "tcp";
        url = "127.0.0.1:29323";
        interval = 60;
        description = "Discord bridge appservice port";
      }
      {
        name = "mautrix-meta-messenger";
        type = "tcp";
        url = "127.0.0.1:29324";
        interval = 60;
        description = "Messenger bridge appservice port";
      }
      {
        name = "mautrix-meta-instagram";
        type = "tcp";
        url = "127.0.0.1:29325";
        interval = 60;
        description = "Instagram bridge appservice port";
      }
      {
        name = "mautrix-linkedin";
        type = "tcp";
        url = "127.0.0.1:29326";
        interval = 60;
        description = "LinkedIn bridge appservice port";
      }

      # DNS Infrastructure
      {
        name = "dnsmasq";
        type = "dns";
        url = "example.com@${config.flags.miniIp}";
        interval = 60;
        description = "dnsmasq DNS resolver";
      }
      {
        name = "stubby";
        type = "tcp";
        url = "${config.flags.miniIp}:5453";
        interval = 60;
        description = "Stubby DoT resolver (upstream for dnsmasq)";
      }

      # Reverse Proxy Infrastructure
      {
        name = "caddy-http";
        type = "tcp";
        url = "${config.flags.miniIp}:80";
        interval = 60;
        description = "Caddy HTTP reverse proxy";
      }
      {
        name = "caddy-https";
        type = "tcp";
        url = "${config.flags.miniIp}:443";
        interval = 60;
        description = "Caddy HTTPS reverse proxy";
      }

      # System Services
      {
        name = "ssh";
        type = "tcp";
        url = "${config.flags.miniIp}:22";
        interval = 60;
        description = "SSH service";
      }
      {
        name = "smb";
        type = "tcp";
        url = "${config.flags.miniIp}:445";
        interval = 60;
        description = "macOS built-in SMB service";
      }
    ];
  };
}
