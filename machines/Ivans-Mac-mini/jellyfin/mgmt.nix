{ config, ... }:

{
  local.services.jellyfin-mgmt = {
    enable = true;
    baseUrl = "http://${config.flags.miniIp}:8096";
    apiKey = config.secrets.jellyfin.apiKey;
    bindAddress = config.flags.miniIp;

    libraries = [
      {
        name = "Movies";
        type = "movies";
        # Co-located with Radarr media on mini
        paths = [ "/Volumes/Storage/Data/media/movies" ];
      }
      {
        name = "Shows";
        type = "tvshows";
        # Co-located with Sonarr media on mini
        paths = [ "/Volumes/Storage/Data/media/tv" ];
      }
    ];
  };
}
