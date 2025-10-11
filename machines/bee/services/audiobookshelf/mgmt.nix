{ config, ... }:
{
  local.services.audiobookshelf-mgmt = {
    enable = true;
    baseUrl = "http://${config.flags.beeIp}:8000";
    apiToken = config.secrets.audiobookshelf.apiToken;

    libraries = [
      {
        name = "Podcasts";
        folders = [ "/storage/Data/media/podcasts" ];
        mediaType = "podcast";
        provider = "itunes";
      }
    ];
  };
}
