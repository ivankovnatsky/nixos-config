{ config, ... }:
{
  local.services.audiobookshelf-mgmt = {
    enable = true;
    baseUrl = "http://${config.flags.beeIp}:8000";
    apiToken = config.secrets.audiobookshelf.apiToken;

    libraries = [
      {
        name = "Podcasts";
        folders = [ "/var/lib/audiobookshelf/media/podcasts" ];
        mediaType = "podcast";
        provider = "itunes";
      }
    ];

    users = [
      {
        username = "textcast";
        password = config.secrets.audiobookshelf.textcastPassword;
        type = "user";
        libraries = [ ]; # Empty = access to all libraries
      }
    ];

    # OPML sync from Podsync
    opmlSync = {
      enable = true;
      opmlUrl = "https://podsync.${config.secrets.externalDomain}/podsync.opml";
      libraryName = "Podcasts"; # Auto-detects library and folder IDs
      autoDownload = true;
      interval = "hourly"; # Run every hour
    };
  };
}
