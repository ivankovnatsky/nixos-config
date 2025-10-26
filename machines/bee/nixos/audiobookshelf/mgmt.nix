{ config, ... }:
{
  sops.secrets.audiobookshelf-api-token = {
    key = "audiobookshelf/apiToken";
  };

  local.services.audiobookshelf-mgmt = {
    enable = true;
    baseUrl = "http://${config.flags.beeIp}:8000";
    apiTokenFile = config.sops.secrets.audiobookshelf-api-token.path;

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
      enable = false;
      opmlUrl = "https://podsync.${config.secrets.externalDomain}/podsync.opml";
      libraryName = "Podcasts"; # Auto-detects library and folder IDs
      autoDownload = true;
      interval = "hourly"; # Run every hour
    };
  };
}
