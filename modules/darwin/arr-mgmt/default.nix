{
  config,
  lib,
  pkgs,
  ...
}:

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
        type = types.nullOr types.str;
        default = null;
        description = "Authentication username (use usernameFile for sops secrets)";
      };

      usernameFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing authentication username";
      };

      password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Authentication password (use passwordFile for sops secrets)";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing authentication password";
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
        type = types.nullOr types.str;
        default = null;
        description = "Application API key (use apiKeyFile for sops secrets)";
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing application API key";
      };

      prowlarrUrl = mkOption {
        type = types.str;
        default = "http://localhost:9696";
        description = "Prowlarr URL as seen by the application";
      };

      syncLevel = mkOption {
        type = types.enum [
          "disabled"
          "addOnly"
          "fullSync"
        ];
        default = "fullSync";
        description = "Synchronization level";
      };

      syncCategories = mkOption {
        type = types.listOf types.int;
        default = [ ];
        example = [
          2000
          2010
          2020
          2030
          2040
          2045
          2050
          2060
          2070
          2080
          2090
        ];
        description = "Categories to sync (torrent category IDs)";
      };

      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable this application";
      };
    };
  };

  prowlarrIndexerSubmodule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        example = "EZTV";
        description = "Indexer display name";
      };

      definitionName = mkOption {
        type = types.str;
        example = "eztv";
        description = "Indexer definition name (lowercase, determines indexer type)";
      };

      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable this indexer";
      };

      priority = mkOption {
        type = types.int;
        default = 25;
        description = "Indexer priority";
      };
    };
  };

  # Base config template without secrets (for reference, not used directly)
  baseConfigTemplate = pkgs.writeText "arr-config-template.json" (
    builtins.toJSON (
      optionalAttrs cfg.radarr.enable {
        radarr = {
          baseUrl = cfg.radarr.baseUrl;
          apiKey = "@RADARR_API_KEY@";
          hostConfig = {
            bindAddress = cfg.radarr.bindAddress;
          };
          downloadClients = map (dc: {
            name = dc.name;
            host = dc.host;
            port = dc.port;
            useSsl = dc.useSsl;
            urlBase = dc.urlBase;
            username = "@DC_${dc.name}_USERNAME@";
            password = "@DC_${dc.name}_PASSWORD@";
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
          apiKey = "@SONARR_API_KEY@";
          hostConfig = {
            bindAddress = cfg.sonarr.bindAddress;
          };
          downloadClients = map (dc: {
            name = dc.name;
            host = dc.host;
            port = dc.port;
            useSsl = dc.useSsl;
            urlBase = dc.urlBase;
            username = "@DC_${dc.name}_USERNAME@";
            password = "@DC_${dc.name}_PASSWORD@";
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
          apiKey = "@PROWLARR_API_KEY@";
          hostConfig = {
            bindAddress = cfg.prowlarr.bindAddress;
          };
          indexers = map (idx: {
            name = idx.name;
            definitionName = idx.definitionName;
            enable = idx.enable;
            priority = idx.priority;
          }) cfg.prowlarr.indexers;
          applications = map (app: {
            name = app.name;
            baseUrl = app.baseUrl;
            apiKey = "@APP_${app.name}_API_KEY@";
            prowlarrUrl = app.prowlarrUrl;
            syncLevel = app.syncLevel;
            syncCategories = app.syncCategories;
            enable = app.enable;
          }) cfg.prowlarr.applications;
        };
      }
    )
  );
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
        type = types.nullOr types.str;
        default = null;
        description = "Radarr API key (use apiKeyFile for sops secrets)";
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing Radarr API key";
      };

      bindAddress = mkOption {
        type = types.str;
        example = "192.168.50.4";
        description = "Bind address for Radarr";
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
        type = types.nullOr types.str;
        default = null;
        description = "Sonarr API key (use apiKeyFile for sops secrets)";
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing Sonarr API key";
      };

      bindAddress = mkOption {
        type = types.str;
        example = "192.168.50.4";
        description = "Bind address for Sonarr";
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
        type = types.nullOr types.str;
        default = null;
        description = "Prowlarr API key (use apiKeyFile for sops secrets)";
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing Prowlarr API key";
      };

      bindAddress = mkOption {
        type = types.str;
        example = "192.168.50.4";
        description = "Bind address for Prowlarr";
      };

      indexers = mkOption {
        type = types.listOf prowlarrIndexerSubmodule;
        default = [ ];
        example = [
          {
            name = "EZTV";
            definitionName = "eztv";
            enable = true;
            priority = 25;
          }
          {
            name = "The Pirate Bay";
            definitionName = "thepiratebay";
            enable = true;
            priority = 25;
          }
        ];
        description = "Indexers to manage in Prowlarr";
      };

      applications = mkOption {
        type = types.listOf prowlarrApplicationSubmodule;
        default = [ ];
        description = "Applications to sync in Prowlarr";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.radarr.enable || (cfg.radarr.apiKey != null) != (cfg.radarr.apiKeyFile != null);
        message = "Exactly one of 'apiKey' or 'apiKeyFile' must be set for radarr";
      }
      {
        assertion = !cfg.sonarr.enable || (cfg.sonarr.apiKey != null) != (cfg.sonarr.apiKeyFile != null);
        message = "Exactly one of 'apiKey' or 'apiKeyFile' must be set for sonarr";
      }
      {
        assertion =
          !cfg.prowlarr.enable || (cfg.prowlarr.apiKey != null) != (cfg.prowlarr.apiKeyFile != null);
        message = "Exactly one of 'apiKey' or 'apiKeyFile' must be set for prowlarr";
      }
    ]
    ++ (lib.optionals cfg.radarr.enable (
      map (dc: {
        assertion = (dc.username != null) != (dc.usernameFile != null);
        message = "Exactly one of 'username' or 'usernameFile' must be set for download client '${dc.name}' in radarr";
      }) cfg.radarr.downloadClients
    ))
    ++ (lib.optionals cfg.radarr.enable (
      map (dc: {
        assertion = (dc.password != null) != (dc.passwordFile != null);
        message = "Exactly one of 'password' or 'passwordFile' must be set for download client '${dc.name}' in radarr";
      }) cfg.radarr.downloadClients
    ))
    ++ (lib.optionals cfg.sonarr.enable (
      map (dc: {
        assertion = (dc.username != null) != (dc.usernameFile != null);
        message = "Exactly one of 'username' or 'usernameFile' must be set for download client '${dc.name}' in sonarr";
      }) cfg.sonarr.downloadClients
    ))
    ++ (lib.optionals cfg.sonarr.enable (
      map (dc: {
        assertion = (dc.password != null) != (dc.passwordFile != null);
        message = "Exactly one of 'password' or 'passwordFile' must be set for download client '${dc.name}' in sonarr";
      }) cfg.sonarr.downloadClients
    ))
    ++ (lib.optionals cfg.prowlarr.enable (
      map (app: {
        assertion = (app.apiKey != null) != (app.apiKeyFile != null);
        message = "Exactly one of 'apiKey' or 'apiKeyFile' must be set for prowlarr application '${app.name}'";
      }) cfg.prowlarr.applications
    ));

    # Darwin launchd service
    local.launchd.services.arr-mgmt = {
      enable = true;
      keepAlive = false;
      runAtLoad = true;

      command =
        let
          syncScript = pkgs.writeShellScript "arr-mgmt-sync" ''
            set -e

            echo "Syncing *arr configuration..."

            # Read secrets from files at runtime
            ${lib.optionalString cfg.radarr.enable (
              if cfg.radarr.apiKeyFile != null then
                ''RADARR_API_KEY="$(cat ${cfg.radarr.apiKeyFile})"''
              else
                ''RADARR_API_KEY="${cfg.radarr.apiKey}"''
            )}
            ${lib.optionalString cfg.sonarr.enable (
              if cfg.sonarr.apiKeyFile != null then
                ''SONARR_API_KEY="$(cat ${cfg.sonarr.apiKeyFile})"''
              else
                ''SONARR_API_KEY="${cfg.sonarr.apiKey}"''
            )}
            ${lib.optionalString cfg.prowlarr.enable (
              if cfg.prowlarr.apiKeyFile != null then
                ''PROWLARR_API_KEY="$(cat ${cfg.prowlarr.apiKeyFile})"''
              else
                ''PROWLARR_API_KEY="${cfg.prowlarr.apiKey}"''
            )}
            ${lib.concatMapStrings (
              dc:
              (
                if dc.usernameFile != null then
                  ''DC_${dc.name}_USERNAME="$(cat ${dc.usernameFile})"'' + "\n"
                else
                  ''DC_${dc.name}_USERNAME="${dc.username}"'' + "\n"
              )
              + (
                if dc.passwordFile != null then
                  ''DC_${dc.name}_PASSWORD="$(cat ${dc.passwordFile})"'' + "\n"
                else
                  ''DC_${dc.name}_PASSWORD="${dc.password}"'' + "\n"
              )
            ) (cfg.radarr.downloadClients ++ cfg.sonarr.downloadClients)}
            ${lib.concatMapStrings (
              app:
              if app.apiKeyFile != null then
                ''APP_${app.name}_API_KEY="$(cat ${app.apiKeyFile})"'' + "\n"
              else
                ''APP_${app.name}_API_KEY="${app.apiKey}"'' + "\n"
            ) cfg.prowlarr.applications}

            # Substitute secrets into template
            ${pkgs.gnused}/bin/sed \
              ${lib.optionalString cfg.radarr.enable ''-e "s|@RADARR_API_KEY@|$RADARR_API_KEY|g"''} \
              ${lib.optionalString cfg.sonarr.enable ''-e "s|@SONARR_API_KEY@|$SONARR_API_KEY|g"''} \
              ${lib.optionalString cfg.prowlarr.enable ''-e "s|@PROWLARR_API_KEY@|$PROWLARR_API_KEY|g"''} \
              ${
                lib.concatMapStringsSep " " (
                  dc:
                  ''-e "s|@DC_${dc.name}_USERNAME@|$DC_${dc.name}_USERNAME|g" -e "s|@DC_${dc.name}_PASSWORD@|$DC_${dc.name}_PASSWORD|g"''
                ) (cfg.radarr.downloadClients ++ cfg.sonarr.downloadClients)
              } \
              ${
                lib.concatMapStringsSep " " (
                  app: ''-e "s|@APP_${app.name}_API_KEY@|$APP_${app.name}_API_KEY|g"''
                ) cfg.prowlarr.applications
              } \
              ${baseConfigTemplate} > /tmp/arr-config.json

            ${pkgs.arr-mgmt}/bin/arr-mgmt sync \
              --config-file /tmp/arr-config.json 2>&1 || echo "Warning: *arr sync failed with exit code $?"

            rm -f /tmp/arr-config.json

            echo "*arr configuration sync completed"
          '';
        in
        "${syncScript}";
    };
  };
}
