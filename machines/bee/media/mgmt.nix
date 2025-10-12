{ config, ... }:

{
  local.services.arr-mgmt = {
    enable = true;

    radarr = {
      enable = true;
      apiKey = config.secrets.arr.radarr.apiKey;
      downloadClients = [
        {
          name = "Transmission";
          host = config.flags.beeIp;
          port = 9091;
          useSsl = false;
          urlBase = "/transmission/";
          username = config.secrets.transmission.username;
          password = config.secrets.transmission.password;
          category = "radarr";
        }
      ];
      rootFolders = [
        "/var/lib/radarr/media/movies"
      ];
    };

    sonarr = {
      enable = true;
      apiKey = config.secrets.arr.sonarr.apiKey;
      downloadClients = [
        {
          name = "Transmission";
          host = config.flags.beeIp;
          port = 9091;
          useSsl = false;
          urlBase = "/transmission/";
          username = config.secrets.transmission.username;
          password = config.secrets.transmission.password;
          category = "tv-sonarr";
        }
      ];
      rootFolders = [
        "/var/lib/sonarr/media/tv"
      ];
    };

    prowlarr = {
      enable = true;
      apiKey = config.secrets.arr.prowlarr.apiKey;
      indexers = [
        { name = "EZTV"; definitionName = "eztv"; enable = true; priority = 25; }
        { name = "LimeTorrents"; definitionName = "limetorrents"; enable = true; priority = 25; }
        { name = "The Pirate Bay"; definitionName = "thepiratebay"; enable = true; priority = 25; }
        # Toloka.to removed - no longer available in Prowlarr upstream
        # TheRARBG removed - RARBG shut down permanently in May 2023
      ];
      applications = [
        {
          name = "Radarr";
          baseUrl = "http://localhost:7878";
          apiKey = config.secrets.arr.radarr.apiKey;
          prowlarrUrl = "http://localhost:9696";
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
          baseUrl = "http://localhost:8989";
          apiKey = config.secrets.arr.sonarr.apiKey;
          prowlarrUrl = "http://localhost:9696";
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
