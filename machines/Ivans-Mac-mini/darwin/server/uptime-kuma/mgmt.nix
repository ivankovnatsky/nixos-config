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
      # Media Stack (mini)
      {
        name = "prowlarr";
        url = "https://prowlarr.@EXTERNAL_DOMAIN@";
        description = "Prowlarr indexer manager (mini:9696)";
      }
      {
        name = "radarr";
        url = "https://radarr.@EXTERNAL_DOMAIN@";
        description = "Radarr movie manager (mini:7878)";
      }
      {
        name = "sonarr";
        url = "https://sonarr.@EXTERNAL_DOMAIN@";
        description = "Sonarr TV manager (mini:8989)";
      }
      {
        name = "transmission";
        url = "https://transmission.@EXTERNAL_DOMAIN@";
        expectedStatus = 401;
        description = "Transmission torrent client with RPC auth (mini:9091)";
      }
      {
        name = "jellyfin";
        url = "https://jellyfin.@EXTERNAL_DOMAIN@";
        description = "Jellyfin media server with WebSocket (mini:8096)";
      }
      {
        name = "stash";
        url = "https://stash.@EXTERNAL_DOMAIN@";
        description = "Stash media organizer with WebSocket (mini:9999)";
      }
      {
        name = "audiobookshelf";
        url = "https://audiobookshelf.@EXTERNAL_DOMAIN@";
        description = "Audiobookshelf audiobook and podcast server (mini:8000)";
      }

      # Infrastructure Services (mini)
      {
        name = "syncthing-mini";
        url = "https://syncthing-mini.@EXTERNAL_DOMAIN@";
        description = "Syncthing on mini (mini:8384)";
      }
      {
        name = "beszel";
        url = "https://beszel.@EXTERNAL_DOMAIN@";
        description = "Beszel monitoring hub (mini:8091)";
      }
      {
        name = "miniserve-mini";
        url = "https://miniserve-mini.@EXTERNAL_DOMAIN@";
        expectedStatus = 401;
        description = "Miniserve file server with auth (mini:8080)";
      }
      {
        name = "bin";
        url = "https://bin.@EXTERNAL_DOMAIN@";
        description = "Pastebin service (mini:8820)";
      }
      {
        name = "podservice";
        url = "https://podservice.@EXTERNAL_DOMAIN@";
        description = "YouTube to Podcast service (mini:8083)";
      }
      {
        name = "textcast";
        url = "https://textcast.@EXTERNAL_DOMAIN@";
        description = "Article to audiobook service (mini:8084)";
      }
      {
        name = "matrix";
        url = "https://matrix.@EXTERNAL_DOMAIN@";
        interval = 30;
        description = "Matrix Synapse server (mini:8009) - Critical service";
      }
      {
        name = "element";
        url = "https://element.@EXTERNAL_DOMAIN@";
        description = "Element web client - Static files";
      }

      # Matrix Bridges (TCP port monitoring - localhost only)
      {
        name = "mautrix-whatsapp";
        type = "tcp";
        url = "127.0.0.1:29321";
        interval = 60;
        description = "WhatsApp bridge appservice port (localhost:29321)";
      }
      {
        name = "mautrix-discord";
        type = "tcp";
        url = "127.0.0.1:29323";
        interval = 60;
        description = "Discord bridge appservice port (localhost:29323)";
      }
      {
        name = "mautrix-meta-messenger";
        type = "tcp";
        url = "127.0.0.1:29324";
        interval = 60;
        description = "Messenger bridge appservice port (localhost:29324)";
      }
      {
        name = "mautrix-meta-instagram";
        type = "tcp";
        url = "127.0.0.1:29325";
        interval = 60;
        description = "Instagram bridge appservice port (localhost:29325)";
      }

      # DNS services (check /dns-query endpoint with example query)
      {
        name = "doh-mini";
        url = "https://doh-mini.@EXTERNAL_DOMAIN@/dns-query?dns=AAABAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB";
        expectedStatus = 200;
        description = "DNS over HTTPS on mini (mini:8053) - queries www.example.com";
      }

      # Ollama (load balanced with failover)
      {
        name = "ollama";
        url = "https://ollama.@EXTERNAL_DOMAIN@";
        description = "Ollama LLM API with failover (a3w:11434 → mini:11434)";
      }
      {
        name = "openwebui";
        url = "https://openwebui.@EXTERNAL_DOMAIN@";
        description = "Open WebUI with WebSocket (mini:8090)";
      }

      # DNS Infrastructure
      {
        name = "dnsmasq-mini";
        type = "dns";
        url = "example.com@${config.flags.miniIp}";
        interval = 60;
        description = "dnsmasq DNS resolver on mini";
      }

      # DNS-over-TLS (Stubby) - Upstream for dnsmasq
      {
        name = "stubby-mini";
        type = "tcp";
        url = "${config.flags.miniIp}:5453";
        interval = 60;
        description = "Stubby DoT resolver on mini (upstream for dnsmasq)";
      }

      # Reverse Proxy Infrastructure
      {
        name = "caddy-mini-http";
        type = "tcp";
        url = "${config.flags.miniIp}:80";
        interval = 60;
        description = "Caddy HTTP on mini (reverse proxy)";
      }
      {
        name = "caddy-mini-https";
        type = "tcp";
        url = "${config.flags.miniIp}:443";
        interval = 60;
        description = "Caddy HTTPS on mini (reverse proxy)";
      }

      {
        name = "ssh-mini";
        type = "tcp";
        url = "${config.flags.miniIp}:22";
        interval = 60;
        description = "SSH service on mini";
      }
    ];
  };
}
