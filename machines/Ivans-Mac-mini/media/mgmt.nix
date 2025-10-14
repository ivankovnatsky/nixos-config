{ config, ... }:

{
  # NOTE: This file is for Phase 3 of the migration (declarative configuration)
  # It should be enabled AFTER Phase 2 (services running with -mini URLs)
  #
  # To enable:
  # 1. Uncomment the import in default.nix
  # 2. Ensure API keys are set in secrets
  # 3. Rebuild mini
  #
  # The arr-mgmt module will automatically configure:
  # - Download clients (Transmission connection)
  # - Root folders (media library paths)
  # - Prowlarr indexers and app connections
  #
  # See machines/bee/media/mgmt.nix for reference

  local.services.arr-mgmt = {
    enable = true;

    radarr = {
      enable = true;
      baseUrl = "http://${config.flags.miniIp}:7878";
      apiKey = config.secrets.arrMini.radarr.apiKey;
      bindAddress = config.flags.miniIp;
      downloadClients = [
        {
          name = "Transmission";
          host = config.flags.miniIp;
          port = 9091;
          useSsl = false;
          urlBase = "/transmission/";
          username = config.secrets.transmission.username;
          password = config.secrets.transmission.password;
          category = "radarr";
        }
      ];
      rootFolders = [
        "/Volumes/Storage/Data/media/movies"
      ];
    };

    sonarr = {
      enable = true;
      baseUrl = "http://${config.flags.miniIp}:8989";
      apiKey = config.secrets.arrMini.sonarr.apiKey;
      bindAddress = config.flags.miniIp;
      downloadClients = [
        {
          name = "Transmission";
          host = config.flags.miniIp;
          port = 9091;
          useSsl = false;
          urlBase = "/transmission/";
          username = config.secrets.transmission.username;
          password = config.secrets.transmission.password;
          category = "tv-sonarr";
        }
      ];
      rootFolders = [
        "/Volumes/Storage/Data/media/tv"
      ];
    };

    prowlarr = {
      enable = true;
      baseUrl = "http://${config.flags.miniIp}:9696";
      apiKey = config.secrets.arrMini.prowlarr.apiKey;
      bindAddress = config.flags.miniIp;
      indexers = [
        { name = "EZTV"; definitionName = "eztv"; enable = true; priority = 25; }
        { name = "LimeTorrents"; definitionName = "limetorrents"; enable = true; priority = 25; }
        { name = "The Pirate Bay"; definitionName = "thepiratebay"; enable = true; priority = 25; }
      ];
      applications = [
        {
          name = "Radarr";
          baseUrl = "http://${config.flags.miniIp}:7878";
          apiKey = config.secrets.arrMini.radarr.apiKey;
          prowlarrUrl = "http://${config.flags.miniIp}:9696";
          syncLevel = "fullSync";
          syncCategories = [
            2000  # Movies
            2010  # Movies/Foreign
            2020  # Movies/Other
            2030  # Movies/SD
            2040  # Movies/HD
            2045  # Movies/UHD
            2050  # Movies/BluRay
            2060  # Movies/3D
            2070  # Movies/DVD
            2080  # Movies/WEB-DL
            2090  # Movies/x265
          ];
        }
        {
          name = "Sonarr";
          baseUrl = "http://${config.flags.miniIp}:8989";
          apiKey = config.secrets.arrMini.sonarr.apiKey;
          prowlarrUrl = "http://${config.flags.miniIp}:9696";
          syncLevel = "fullSync";
          syncCategories = [
            5000  # TV
            5010  # TV/WEB-DL
            5020  # TV/Foreign
            5030  # TV/SD
            5040  # TV/HD
            5045  # TV/UHD
            5050  # TV/Other
            5090  # TV/x265
          ];
        }
      ];
    };
  };
}
