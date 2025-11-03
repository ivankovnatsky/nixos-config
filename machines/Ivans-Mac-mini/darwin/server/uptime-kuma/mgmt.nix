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
  sops.secrets.external-domain = {
    key = "externalDomain";
    owner = "root";
  };
  sops.secrets.uptime-kuma-username = {
    key = "uptimeKuma/username";
    owner = "root";
  };
  sops.secrets.uptime-kuma-password = {
    key = "uptimeKuma/password";
    owner = "root";
  };
  sops.secrets.discord-webhook = {
    key = "discordWebHook";
    owner = "root";
  };
  sops.secrets.postgres-monitoring-password = {
    key = "postgres/monitoring/password";
    owner = "root";
  };

  local.services.uptime-kuma-mgmt = {
    enable = true;
    # Base URL will be constructed at runtime from external-domain secret
    baseUrl = "https://kuma.@EXTERNAL_DOMAIN@";
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

      # Infrastructure Services (bee)
      {
        name = "audiobookshelf";
        url = "https://audiobookshelf.@EXTERNAL_DOMAIN@";
        description = "Audiobookshelf with WebSocket (bee:8000)";
      }
      {
        name = "homeassistant";
        url = "https://homeassistant.@EXTERNAL_DOMAIN@";
        interval = 30;
        description = "Home Assistant (bee:8123) - Critical service";
      }
      {
        name = "matrix";
        url = "https://matrix.@EXTERNAL_DOMAIN@";
        interval = 30;
        description = "Matrix Synapse server (bee:8008) - Critical service";
      }
      {
        name = "element";
        url = "https://element.@EXTERNAL_DOMAIN@";
        description = "Element web client - Static files";
      }
      {
        name = "openwebui";
        url = "https://openwebui.@EXTERNAL_DOMAIN@";
        description = "OpenWebUI with WebSocket (bee:8090)";
      }
      {
        name = "syncthing-bee";
        url = "https://syncthing-bee.@EXTERNAL_DOMAIN@";
        description = "Syncthing on bee (bee:8384)";
      }
      {
        name = "homebridge";
        url = "https://homebridge.@EXTERNAL_DOMAIN@";
        description = "Homebridge UI (bee:8581)";
      }
      {
        name = "matterbridge";
        url = "https://matterbridge.@EXTERNAL_DOMAIN@";
        description = "Matterbridge UI (bee:8283)";
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

      # Auth-protected services (expect 401)
      {
        name = "zigbee";
        url = "https://zigbee.@EXTERNAL_DOMAIN@";
        expectedStatus = 401;
        description = "Zigbee2MQTT with basic auth (bee:8081)";
      }
      {
        name = "netdata-mini";
        url = "https://netdata-mini.@EXTERNAL_DOMAIN@";
        expectedStatus = 401;
        description = "Netdata monitoring with basic auth (mini:19999)";
      }

      # DNS services (check /dns-query endpoint with example query)
      {
        name = "doh-bee";
        url = "https://doh-bee.@EXTERNAL_DOMAIN@/dns-query?dns=AAABAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB";
        expectedStatus = 200;
        description = "DNS over HTTPS on bee (bee:8053) - queries www.example.com";
      }
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

      # Backend Infrastructure - Database & Message Broker
      {
        name = "postgresql-bee";
        type = "postgres";
        url = "postgres://postgres_monitor:@POSTGRES_PASSWORD@@@BEE_IP@:5432/postgres";
        interval = 60;
        description = "PostgreSQL database on bee (Home Assistant, Matrix)";
      }
      {
        name = "mosquitto-bee";
        type = "tcp";
        url = "${config.flags.beeIp}:1883";
        interval = 60;
        description = "Mosquitto MQTT broker on bee (Zigbee2MQTT, IoT)";
      }

      # DNS Infrastructure
      {
        name = "dnsmasq-bee";
        type = "dns";
        url = "example.com@${config.flags.beeIp}";
        interval = 60;
        description = "dnsmasq DNS resolver on bee";
      }
      {
        name = "dnsmasq-mini";
        type = "dns";
        url = "example.com@${config.flags.miniIp}";
        interval = 60;
        description = "dnsmasq DNS resolver on mini";
      }

      # DNS-over-TLS (Stubby) - Upstream for dnsmasq
      {
        name = "stubby-bee";
        type = "tcp";
        url = "${config.flags.beeIp}:5453";
        interval = 60;
        description = "Stubby DoT resolver on bee (upstream for dnsmasq)";
      }
      {
        name = "stubby-mini";
        type = "tcp";
        url = "${config.flags.miniIp}:5453";
        interval = 60;
        description = "Stubby DoT resolver on mini (upstream for dnsmasq)";
      }

      # Reverse Proxy Infrastructure
      {
        name = "caddy-bee-http";
        type = "tcp";
        url = "${config.flags.beeIp}:80";
        interval = 60;
        description = "Caddy HTTP on bee (reverse proxy)";
      }
      {
        name = "caddy-bee-https";
        type = "tcp";
        url = "${config.flags.beeIp}:443";
        interval = 60;
        description = "Caddy HTTPS on bee (reverse proxy)";
      }
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

      # Home Automation Infrastructure
      {
        name = "matter-server-bee";
        type = "tcp";
        url = "${config.flags.beeIp}:5580";
        interval = 60;
        description = "Matter Server WebSocket on bee (Home Assistant integration)";
      }

      # VPN Mesh Network
      {
        name = "tailscale-bee";
        type = "tailscale-ping";
        url = "bee";
        interval = 60;
        description = "Tailscale VPN connectivity for bee";
      }

      # SSH Services
      {
        name = "ssh-bee";
        type = "tcp";
        url = "${config.flags.beeIp}:22";
        interval = 60;
        description = "SSH service on bee";
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
