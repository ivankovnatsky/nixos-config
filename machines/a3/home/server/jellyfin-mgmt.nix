{ config, ... }:

{
  sops.secrets.jellyfin-api-key = {
    key = "jellyfin/apiKey";
  };

  local.services.jellyfin-mgmt = {
    enable = true;
    baseUrl = "http://127.0.0.1:8096";
    apiKeyFile = config.sops.secrets.jellyfin-api-key.path;
    # Bind to all interfaces: mgmt/Kuma probe use loopback while LAN clients
    # and Caddy reach the server on a3Ip. Setting this to a single IP would
    # cause Jellyfin to stop listening on 127.0.0.1 after the first sync.
    bindAddress = "0.0.0.0";

    libraries = [
      {
        name = "Movies";
        type = "movies";
        # Co-located with Radarr media on a3
        paths = [ "/storage/data/media/movies" ];
        enableRealtimeMonitor = true;
        automaticRefreshIntervalDays = 7;
      }
      {
        name = "Shows";
        type = "tvshows";
        # Co-located with Sonarr media on a3
        paths = [ "/storage/data/media/tv" ];
        enableRealtimeMonitor = true;
        automaticRefreshIntervalDays = 7;
      }
    ];
  };
}
