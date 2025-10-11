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
  };
}
