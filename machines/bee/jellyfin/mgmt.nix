{ config, ... }:

{
  local.services.jellyfin-mgmt = {
    enable = true;
    baseUrl = "http://localhost:8096";
    apiKey = config.secrets.jellyfin.apiKey;

    libraries = [
      {
        name = "Movies";
        type = "movies";
        # Use same directory as Radarr manages
        paths = [ "/var/lib/radarr/media/movies" ];
      }
      {
        name = "Shows";
        type = "tvshows";
        # Use same directory as Sonarr manages
        paths = [ "/var/lib/sonarr/media/tv" ];
      }
    ];
  };
}
