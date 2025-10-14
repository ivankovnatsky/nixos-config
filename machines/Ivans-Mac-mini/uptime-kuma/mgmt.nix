{ config, ... }:

{
  # Uptime Kuma declarative monitor management
  # Automatically syncs monitors from Nix configuration on system activation
  #
  # Manual operations:
  # - List monitors: uptime-kuma-mgmt list --base-url https://uptime.${config.secrets.externalDomain} --username ${config.secrets.uptimeKuma.username} --password ${config.secrets.uptimeKuma.password}
  # - Dry-run sync: Temporarily set enable = false and run manually with --dry-run
  #
  # Initial setup required:
  # 1. Access https://uptime.${config.secrets.externalDomain}
  # 2. Create admin account matching credentials in config.secrets.uptimeKuma
  # 3. Monitors will auto-sync on next rebuild

  local.services.uptime-kuma-mgmt = {
    enable = true;
    baseUrl = "https://uptime.${config.secrets.externalDomain}";
    username = config.secrets.uptimeKuma.username;
    password = config.secrets.uptimeKuma.password;

    monitors = [
      # Media Stack (mini)
      {
        name = "prowlarr";
        url = "https://prowlarr.${config.secrets.externalDomain}";
        description = "Prowlarr indexer manager (mini:9696)";
      }
      {
        name = "radarr";
        url = "https://radarr.${config.secrets.externalDomain}";
        description = "Radarr movie manager (mini:7878)";
      }
      {
        name = "sonarr";
        url = "https://sonarr.${config.secrets.externalDomain}";
        description = "Sonarr TV manager (mini:8989)";
      }
      {
        name = "transmission";
        url = "https://transmission.${config.secrets.externalDomain}";
        expectedStatus = 401;
        description = "Transmission torrent client with RPC auth (mini:9091)";
      }
      {
        name = "jellyfin";
        url = "https://jellyfin.${config.secrets.externalDomain}";
        description = "Jellyfin media server with WebSocket (mini:8096)";
      }
      {
        name = "stash";
        url = "https://stash.${config.secrets.externalDomain}";
        description = "Stash media organizer with WebSocket (mini:9999)";
      }

      # Infrastructure Services (bee)
      {
        name = "audiobookshelf";
        url = "https://audiobookshelf.${config.secrets.externalDomain}";
        description = "Audiobookshelf with WebSocket (bee:8000)";
      }
      {
        name = "homeassistant";
        url = "https://homeassistant.${config.secrets.externalDomain}";
        interval = 30;
        description = "Home Assistant (bee:8123) - Critical service";
      }
      {
        name = "matrix";
        url = "https://matrix.${config.secrets.externalDomain}";
        interval = 30;
        description = "Matrix Synapse server (bee:8008) - Critical service";
      }
      {
        name = "element";
        url = "https://element.${config.secrets.externalDomain}";
        description = "Element web client - Static files";
      }
      {
        name = "openwebui";
        url = "https://openwebui.${config.secrets.externalDomain}";
        description = "OpenWebUI with WebSocket (bee:8090)";
      }
      {
        name = "sync-bee";
        url = "https://sync-bee.${config.secrets.externalDomain}";
        description = "Syncthing on bee (bee:8384)";
      }
      {
        name = "homebridge";
        url = "https://homebridge.${config.secrets.externalDomain}";
        description = "Homebridge UI (bee:8581)";
      }
      {
        name = "matterbridge";
        url = "https://matterbridge.${config.secrets.externalDomain}";
        description = "Matterbridge UI (bee:8283)";
      }

      # Infrastructure Services (mini)
      {
        name = "sync-mini";
        url = "https://sync-mini.${config.secrets.externalDomain}";
        description = "Syncthing on mini (mini:8384)";
      }
      {
        name = "beszel";
        url = "https://beszel.${config.secrets.externalDomain}";
        description = "Beszel monitoring hub (mini:8091)";
      }
      {
        name = "files-mini";
        url = "https://files-mini.${config.secrets.externalDomain}";
        expectedStatus = 401;
        description = "Miniserve file server with auth (mini:8080)";
      }
      {
        name = "bin";
        url = "https://bin.${config.secrets.externalDomain}";
        description = "Pastebin service (mini:8820)";
      }

      # Auth-protected services (expect 401)
      {
        name = "zigbee";
        url = "https://zigbee.${config.secrets.externalDomain}";
        expectedStatus = 401;
        description = "Zigbee2MQTT with basic auth (bee:8081)";
      }
      {
        name = "netdata-mini";
        url = "https://netdata-mini.${config.secrets.externalDomain}";
        expectedStatus = 401;
        description = "Netdata monitoring with basic auth (mini:19999)";
      }

      # DNS services (check /dns-query endpoint with example query)
      {
        name = "dns-mini";
        url = "https://dns-mini.${config.secrets.externalDomain}/dns-query?dns=AAABAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB";
        expectedStatus = 200;
        description = "DNS over HTTPS on mini (mini:8053) - queries www.example.com";
      }

      # Ollama (load balanced with failover)
      {
        name = "ollama";
        url = "https://ollama.${config.secrets.externalDomain}";
        description = "Ollama LLM API with failover (a3w:11434 → mini:11434)";
      }
    ];
  };
}
