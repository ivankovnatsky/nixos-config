{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.services.arr-mgmt;

  downloadClientSubmodule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        example = "Transmission";
        description = "Download client name";
      };

      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "Download client hostname";
      };

      port = mkOption {
        type = types.int;
        default = 9091;
        description = "Download client port";
      };

      useSsl = mkOption {
        type = types.bool;
        default = false;
        description = "Use SSL for connection";
      };

      urlBase = mkOption {
        type = types.str;
        default = "/transmission/";
        description = "URL base path";
      };

      username = mkOption {
        type = types.str;
        description = "Authentication username";
      };

      password = mkOption {
        type = types.str;
        description = "Authentication password";
      };

      category = mkOption {
        type = types.str;
        default = "";
        description = "Download category for this client";
      };

      addPaused = mkOption {
        type = types.bool;
        default = false;
        description = "Add downloads in paused state";
      };

      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable this download client";
      };

      priority = mkOption {
        type = types.int;
        default = 1;
        description = "Download client priority";
      };

      removeCompletedDownloads = mkOption {
        type = types.bool;
        default = true;
        description = "Remove completed downloads";
      };

      removeFailedDownloads = mkOption {
        type = types.bool;
        default = true;
        description = "Remove failed downloads";
      };
    };
  };

  prowlarrApplicationSubmodule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        example = "Radarr";
        description = "Application name";
      };

      baseUrl = mkOption {
        type = types.str;
        example = "http://localhost:7878";
        description = "Application base URL";
      };

      apiKey = mkOption {
        type = types.str;
        description = "Application API key";
      };

      prowlarrUrl = mkOption {
        type = types.str;
        default = "http://localhost:9696";
        description = "Prowlarr URL as seen by the application";
      };

      syncLevel = mkOption {
        type = types.enum [ "disabled" "addOnly" "fullSync" ];
        default = "fullSync";
        description = "Synchronization level";
      };

      syncCategories = mkOption {
        type = types.listOf types.int;
        default = [ ];
        example = [ 2000 2010 2020 2030 2040 2045 2050 2060 2070 2080 2090 ];
        description = "Categories to sync (torrent category IDs)";
      };

      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable this application";
      };
    };
  };

  configJson = pkgs.writeText "arr-config.json" (builtins.toJSON (
    optionalAttrs cfg.radarr.enable {
      radarr = {
        baseUrl = cfg.radarr.baseUrl;
        apiKey = cfg.radarr.apiKey;
        downloadClients = map (dc: {
          name = dc.name;
          host = dc.host;
          port = dc.port;
          useSsl = dc.useSsl;
          urlBase = dc.urlBase;
          username = dc.username;
          password = dc.password;
          category = dc.category;
          addPaused = dc.addPaused;
          enable = dc.enable;
          priority = dc.priority;
          removeCompletedDownloads = dc.removeCompletedDownloads;
          removeFailedDownloads = dc.removeFailedDownloads;
        }) cfg.radarr.downloadClients;
        rootFolders = cfg.radarr.rootFolders;
      };
    }
    // optionalAttrs cfg.sonarr.enable {
      sonarr = {
        baseUrl = cfg.sonarr.baseUrl;
        apiKey = cfg.sonarr.apiKey;
        downloadClients = map (dc: {
          name = dc.name;
          host = dc.host;
          port = dc.port;
          useSsl = dc.useSsl;
          urlBase = dc.urlBase;
          username = dc.username;
          password = dc.password;
          category = dc.category;
          addPaused = dc.addPaused;
          enable = dc.enable;
          priority = dc.priority;
          removeCompletedDownloads = dc.removeCompletedDownloads;
          removeFailedDownloads = dc.removeFailedDownloads;
        }) cfg.sonarr.downloadClients;
        rootFolders = cfg.sonarr.rootFolders;
      };
    }
    // optionalAttrs cfg.prowlarr.enable {
      prowlarr = {
        baseUrl = cfg.prowlarr.baseUrl;
        apiKey = cfg.prowlarr.apiKey;
        applications = map (app: {
          name = app.name;
          baseUrl = app.baseUrl;
          apiKey = app.apiKey;
          prowlarrUrl = app.prowlarrUrl;
          syncLevel = app.syncLevel;
          syncCategories = app.syncCategories;
          enable = app.enable;
        }) cfg.prowlarr.applications;
      };
    }
  ));
in
{
  options.local.services.arr-mgmt = {
    enable = mkEnableOption "declarative *arr stack configuration synchronization";

    radarr = {
      enable = mkEnableOption "Radarr synchronization";

      baseUrl = mkOption {
        type = types.str;
        default = "http://localhost:7878";
        description = "Radarr base URL";
      };

      apiKey = mkOption {
        type = types.str;
        description = "Radarr API key";
      };

      downloadClients = mkOption {
        type = types.listOf downloadClientSubmodule;
        default = [ ];
        description = "Download clients to configure in Radarr";
      };

      rootFolders = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "/storage/Data/media/movies" ];
        description = "Root folders for Radarr";
      };
    };

    sonarr = {
      enable = mkEnableOption "Sonarr synchronization";

      baseUrl = mkOption {
        type = types.str;
        default = "http://localhost:8989";
        description = "Sonarr base URL";
      };

      apiKey = mkOption {
        type = types.str;
        description = "Sonarr API key";
      };

      downloadClients = mkOption {
        type = types.listOf downloadClientSubmodule;
        default = [ ];
        description = "Download clients to configure in Sonarr";
      };

      rootFolders = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "/storage/Data/media/tv" ];
        description = "Root folders for Sonarr";
      };
    };

    prowlarr = {
      enable = mkEnableOption "Prowlarr synchronization";

      baseUrl = mkOption {
        type = types.str;
        default = "http://localhost:9696";
        description = "Prowlarr base URL";
      };

      apiKey = mkOption {
        type = types.str;
        description = "Prowlarr API key";
      };

      applications = mkOption {
        type = types.listOf prowlarrApplicationSubmodule;
        default = [ ];
        description = "Applications to sync in Prowlarr";
      };
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.arr-mgmt = ''
      echo "Syncing *arr configuration..."
      ${pkgs.arr-mgmt}/bin/arr-mgmt sync \
        --config-file "${configJson}" || echo "Warning: *arr sync failed"
    '';
  };
}
