{ config, ... }:
{
  # Declarative library management for Audiobookshelf
  # Syncs library configuration on every rebuild
  local.services.audiobookshelf-mgmt = {
    enable = true;
    baseUrl = "http://localhost:8000";
    apiToken = config.secrets.audiobookshelf.apiToken;

    libraries = [
      {
        name = "Podcasts";
        folders = [ "/mnt/mac/Volumes/Storage/Data/media/podcasts" ];
        mediaType = "podcast";
        provider = "itunes";
      }
    ];
  };
}
