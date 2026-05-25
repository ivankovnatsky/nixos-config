{ config, ... }:

let
  mediaDir = "/storage/data/media";
in
{
  # Home-manager sops secrets for the *arr stack on a3. Defined here at the
  # user level (in addition to the system-level transmission secrets owned by
  # the transmission user) so the user-systemd arr-mgmt sync can read them.
  sops.secrets.arr-radarr-api-key = {
    key = "arr/radarr/apiKey";
  };
  sops.secrets.arr-sonarr-api-key = {
    key = "arr/sonarr/apiKey";
  };
  sops.secrets.arr-prowlarr-api-key = {
    key = "arr/prowlarr/apiKey";
  };
  sops.secrets.arr-lidarr-api-key = {
    key = "arr/lidarr/apiKey";
  };
  sops.secrets.arr-transmission-username = {
    key = "transmission/username";
  };
  sops.secrets.arr-transmission-password = {
    key = "transmission/password";
  };
  sops.secrets.arr-toloka-username = {
    key = "arr/indexers/toloka/username";
  };
  sops.secrets.arr-toloka-password = {
    key = "arr/indexers/toloka/password";
  };

  local.services.arr-mgmt = {
    enable = true;

    lidarr = {
      enable = true;
      baseUrl = "http://127.0.0.1:8686";
      apiKeyFile = config.sops.secrets.arr-lidarr-api-key.path;
      bindAddress = "*";
      downloadClients = [
        {
          name = "Transmission";
          host = "127.0.0.1";
          port = 9091;
          useSsl = false;
          urlBase = "/transmission/";
          usernameFile = config.sops.secrets.arr-transmission-username.path;
          passwordFile = config.sops.secrets.arr-transmission-password.path;
          category = "lidarr";
        }
      ];
      rootFolders = [
        "/storage/data/music"
      ];
    };

    radarr = {
      enable = true;
      baseUrl = "http://127.0.0.1:7878";
      apiKeyFile = config.sops.secrets.arr-radarr-api-key.path;
      bindAddress = "*";
      downloadClients = [
        {
          name = "Transmission";
          host = "127.0.0.1";
          port = 9091;
          useSsl = false;
          urlBase = "/transmission/";
          usernameFile = config.sops.secrets.arr-transmission-username.path;
          passwordFile = config.sops.secrets.arr-transmission-password.path;
          category = "radarr";
        }
      ];
      rootFolders = [
        "${mediaDir}/movies"
      ];
    };

    sonarr = {
      enable = true;
      baseUrl = "http://127.0.0.1:8989";
      apiKeyFile = config.sops.secrets.arr-sonarr-api-key.path;
      bindAddress = "*";
      downloadClients = [
        {
          name = "Transmission";
          host = "127.0.0.1";
          port = 9091;
          useSsl = false;
          urlBase = "/transmission/";
          usernameFile = config.sops.secrets.arr-transmission-username.path;
          passwordFile = config.sops.secrets.arr-transmission-password.path;
          category = "tv-sonarr";
        }
      ];
      rootFolders = [
        "${mediaDir}/tv"
      ];
    };

    prowlarr = {
      enable = true;
      baseUrl = "http://127.0.0.1:9696";
      apiKeyFile = config.sops.secrets.arr-prowlarr-api-key.path;
      bindAddress = "*";
      indexers = [
        {
          name = "The Pirate Bay";
          definitionName = "thepiratebay";
          enable = true;
          priority = 25;
        }
        {
          name = "Toloka.to";
          definitionName = "Toloka.to";
          enable = true;
          priority = 25;
          usernameFile = config.sops.secrets.arr-toloka-username.path;
          passwordFile = config.sops.secrets.arr-toloka-password.path;
        }
      ];
      applications = [
        {
          name = "Lidarr";
          baseUrl = "http://127.0.0.1:8686";
          apiKeyFile = config.sops.secrets.arr-lidarr-api-key.path;
          prowlarrUrl = "http://127.0.0.1:9696";
          syncLevel = "fullSync";
          syncCategories = [
            3000 # Audio
            3010 # Audio/MP3
            3020 # Audio/Video
            3030 # Audio/Audiobook
            3040 # Audio/Lossless
          ];
        }
        {
          name = "Radarr";
          baseUrl = "http://127.0.0.1:7878";
          apiKeyFile = config.sops.secrets.arr-radarr-api-key.path;
          prowlarrUrl = "http://127.0.0.1:9696";
          syncLevel = "fullSync";
          syncCategories = [
            2000 # Movies
            2010 # Movies/Foreign
            2020 # Movies/Other
            2030 # Movies/SD
            2040 # Movies/HD
            2045 # Movies/UHD
            2050 # Movies/BluRay
            2060 # Movies/3D
            2070 # Movies/DVD
            2080 # Movies/WEB-DL
            2090 # Movies/x265
          ];
        }
        {
          name = "Sonarr";
          baseUrl = "http://127.0.0.1:8989";
          apiKeyFile = config.sops.secrets.arr-sonarr-api-key.path;
          prowlarrUrl = "http://127.0.0.1:9696";
          syncLevel = "fullSync";
          syncCategories = [
            5000 # TV
            5010 # TV/WEB-DL
            5020 # TV/Foreign
            5030 # TV/SD
            5040 # TV/HD
            5045 # TV/UHD
            5050 # TV/Other
            5090 # TV/x265
          ];
        }
      ];
    };
  };
}
