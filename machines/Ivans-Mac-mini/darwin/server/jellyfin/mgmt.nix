{ config, ... }:

{
  sops.secrets.jellyfin-api-key = {
    key = "jellyfin/apiKey";
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
        paths = [ "/Volumes/Storage/Data/Media/Movies" ];
      }
      {
        name = "Shows";
        type = "tvshows";
        # Co-located with Sonarr media on mini
        paths = [ "/Volumes/Storage/Data/Media/TV" ];
      }
    ];
  };
}
