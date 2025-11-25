{ config, ... }:

{
  sops.secrets.jellyfin-api-key = {
    key = "jellyfin/apiKey";
    owner = "ivan";
  };

  local.services.jellyfin-mgmt = {
    enable = true;
    baseUrl = "http://${config.flags.miniIp}:8096";
    apiKeyFile = config.sops.secrets.jellyfin-api-key.path;
    bindAddress = config.flags.miniIp;

    libraries = [
      {
        name = "Movies";
        type = "movies";
        # Co-located with Radarr media on mini
        paths = [ "${config.flags.miniStoragePath}/Media/Movies" ];
        # Enable real-time file system monitoring
        enableRealtimeMonitor = true;
        # Automatic metadata refresh every 7 days
        automaticRefreshIntervalDays = 7;
      }
      {
        name = "Shows";
        type = "tvshows";
        # Co-located with Sonarr media on mini
        paths = [ "${config.flags.miniStoragePath}/Media/TV" ];
        # Enable real-time file system monitoring
        enableRealtimeMonitor = true;
        # Automatic metadata refresh every 7 days
        automaticRefreshIntervalDays = 7;
      }
    ];
  };
}
