{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.arr-mgmt;

  # Sanitize names for use as shell variable identifiers
  # Replace dots, spaces, hyphens with underscores
  sanitize =
    name:
    builtins.replaceStrings
      [
        "."
        " "
        "-"
      ]
      [
        "_"
        "_"
        "_"
      ]
      name;

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

      username = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Indexer username (use usernameFile for sops secrets)";
      };

      usernameFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing indexer username";
      };

      password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Indexer password (use passwordFile for sops secrets)";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing indexer password";
      };
    };
  };

  # Base config template without secrets (for reference, not used directly)
  baseConfigTemplate = pkgs.writeText "arr-config-template.json" (
    builtins.toJSON (
      optionalAttrs cfg.radarr.enable {
        radarr = {
          inherit (cfg.radarr) baseUrl;
          apiKey = "$RADARR_API_KEY";
          hostConfig = {
            inherit (cfg.radarr) bindAddress;
          };
          downloadClients = map (dc: {
            inherit (dc) name;
            inherit (dc) host;
            inherit (dc) port;
            inherit (dc) useSsl;
            inherit (dc) urlBase;
            username = "$DC_${sanitize dc.name}_USERNAME";
            password = "$DC_${sanitize dc.name}_PASSWORD";
            inherit (dc) category;
            inherit (dc) addPaused;
            inherit (dc) enable;
            inherit (dc) priority;
            inherit (dc) removeCompletedDownloads;
            inherit (dc) removeFailedDownloads;
          }) cfg.radarr.downloadClients;
          inherit (cfg.radarr) rootFolders;
        };
      }
      // optionalAttrs cfg.lidarr.enable {
        lidarr = {
          inherit (cfg.lidarr) baseUrl;
          apiKey = "$LIDARR_API_KEY";
          hostConfig = {
            inherit (cfg.lidarr) bindAddress;
          };
          downloadClients = map (dc: {
            inherit (dc) name;
            inherit (dc) host;
            inherit (dc) port;
            inherit (dc) useSsl;
            inherit (dc) urlBase;
            username = "$DC_${sanitize dc.name}_USERNAME";
            password = "$DC_${sanitize dc.name}_PASSWORD";
            inherit (dc) category;
            inherit (dc) addPaused;
            inherit (dc) enable;
            inherit (dc) priority;
            inherit (dc) removeCompletedDownloads;
            inherit (dc) removeFailedDownloads;
          }) cfg.lidarr.downloadClients;
          inherit (cfg.lidarr) rootFolders;
        };
      }
      // optionalAttrs cfg.sonarr.enable {
        sonarr = {
          inherit (cfg.sonarr) baseUrl;
          apiKey = "$SONARR_API_KEY";
          hostConfig = {
            inherit (cfg.sonarr) bindAddress;
          };
          downloadClients = map (dc: {
            inherit (dc) name;
            inherit (dc) host;
            inherit (dc) port;
            inherit (dc) useSsl;
            inherit (dc) urlBase;
            username = "$DC_${sanitize dc.name}_USERNAME";
            password = "$DC_${sanitize dc.name}_PASSWORD";
            inherit (dc) category;
            inherit (dc) addPaused;
            inherit (dc) enable;
            inherit (dc) priority;
            inherit (dc) removeCompletedDownloads;
            inherit (dc) removeFailedDownloads;
          }) cfg.sonarr.downloadClients;
          inherit (cfg.sonarr) rootFolders;
        };
      }
      // optionalAttrs cfg.prowlarr.enable {
        prowlarr = {
          inherit (cfg.prowlarr) baseUrl;
          apiKey = "$PROWLARR_API_KEY";
          hostConfig = {
            inherit (cfg.prowlarr) bindAddress;
          };
          indexers = map (
            idx:
            {
              inherit (idx) name;
              inherit (idx) definitionName;
              inherit (idx) enable;
              inherit (idx) priority;
            }
            // optionalAttrs (idx.username != null || idx.usernameFile != null) {
              username = "$IDX_${sanitize idx.name}_USERNAME";
              password = "$IDX_${sanitize idx.name}_PASSWORD";
            }
          ) cfg.prowlarr.indexers;
          applications = map (app: {
            inherit (app) name;
            inherit (app) baseUrl;
            apiKey = "$APP_${sanitize app.name}_API_KEY";
            inherit (app) prowlarrUrl;
            inherit (app) syncLevel;
            inherit (app) syncCategories;
            inherit (app) enable;
          }) cfg.prowlarr.applications;
        };
      }
    )
  );

  syncScript = pkgs.writeShellScript "arr-mgmt-sync" ''
    set -e

    echo "Syncing *arr configuration..."

    # Wait for services to be reachable
    wait_for_service() {
      local url="$1"
      local name="$2"
      local max_retries=30
      local retry=0
      while [ $retry -lt $max_retries ]; do
        if ${pkgs.curl}/bin/curl -sf -o /dev/null "$url/ping" 2>/dev/null || \
           ${pkgs.curl}/bin/curl -sf -o /dev/null "$url" 2>/dev/null; then
          echo "$name is reachable"
          return 0
        fi
        retry=$((retry + 1))
        echo "Waiting for $name ($retry/$max_retries)..."
        sleep 2
      done
      echo "ERROR: $name not reachable after $max_retries retries"
      return 1
    }

    ${lib.optionalString cfg.lidarr.enable ''wait_for_service "${cfg.lidarr.baseUrl}" "Lidarr" || true''}
    ${lib.optionalString cfg.radarr.enable ''wait_for_service "${cfg.radarr.baseUrl}" "Radarr" || true''}
    ${lib.optionalString cfg.sonarr.enable ''wait_for_service "${cfg.sonarr.baseUrl}" "Sonarr" || true''}
    ${lib.optionalString cfg.prowlarr.enable ''wait_for_service "${cfg.prowlarr.baseUrl}" "Prowlarr" || true''}

    # Read secrets from files at runtime
    ${lib.optionalString cfg.lidarr.enable (
      if cfg.lidarr.apiKeyFile != null then
        ''LIDARR_API_KEY="$(${pkgs.coreutils}/bin/cat ${cfg.lidarr.apiKeyFile})"''
      else
        ''LIDARR_API_KEY="${cfg.lidarr.apiKey}"''
    )}
    ${lib.optionalString cfg.radarr.enable (
      if cfg.radarr.apiKeyFile != null then
        ''RADARR_API_KEY="$(${pkgs.coreutils}/bin/cat ${cfg.radarr.apiKeyFile})"''
      else
        ''RADARR_API_KEY="${cfg.radarr.apiKey}"''
    )}
    ${lib.optionalString cfg.sonarr.enable (
      if cfg.sonarr.apiKeyFile != null then
        ''SONARR_API_KEY="$(${pkgs.coreutils}/bin/cat ${cfg.sonarr.apiKeyFile})"''
      else
        ''SONARR_API_KEY="${cfg.sonarr.apiKey}"''
    )}
    ${lib.optionalString cfg.prowlarr.enable (
      if cfg.prowlarr.apiKeyFile != null then
        ''PROWLARR_API_KEY="$(${pkgs.coreutils}/bin/cat ${cfg.prowlarr.apiKeyFile})"''
      else
        ''PROWLARR_API_KEY="${cfg.prowlarr.apiKey}"''
    )}
    ${lib.concatMapStrings (
      dc:
      (
        if dc.usernameFile != null then
          ''DC_${sanitize dc.name}_USERNAME="$(${pkgs.coreutils}/bin/cat ${dc.usernameFile})"'' + "\n"
        else
          ''DC_${sanitize dc.name}_USERNAME="${dc.username}"'' + "\n"
      )
      + (
        if dc.passwordFile != null then
          ''DC_${sanitize dc.name}_PASSWORD="$(${pkgs.coreutils}/bin/cat ${dc.passwordFile})"'' + "\n"
        else
          ''DC_${sanitize dc.name}_PASSWORD="${dc.password}"'' + "\n"
      )
    ) (cfg.lidarr.downloadClients ++ cfg.radarr.downloadClients ++ cfg.sonarr.downloadClients)}
    ${lib.concatMapStrings (
      app:
      if app.apiKeyFile != null then
        ''APP_${sanitize app.name}_API_KEY="$(${pkgs.coreutils}/bin/cat ${app.apiKeyFile})"'' + "\n"
      else
        ''APP_${sanitize app.name}_API_KEY="${app.apiKey}"'' + "\n"
    ) cfg.prowlarr.applications}
    ${lib.concatMapStrings (
      idx:
      lib.optionalString (idx.username != null || idx.usernameFile != null) (
        (
          if idx.usernameFile != null then
            ''IDX_${sanitize idx.name}_USERNAME="$(${pkgs.coreutils}/bin/cat ${idx.usernameFile})"'' + "\n"
          else
            ''IDX_${sanitize idx.name}_USERNAME="${idx.username}"'' + "\n"
        )
        + (
          if idx.passwordFile != null then
            ''IDX_${sanitize idx.name}_PASSWORD="$(${pkgs.coreutils}/bin/cat ${idx.passwordFile})"'' + "\n"
          else
            ''IDX_${sanitize idx.name}_PASSWORD="${idx.password}"'' + "\n"
        )
      )
    ) cfg.prowlarr.indexers}

    # Substitute secrets into template
    # Export all secrets for envsubst
    ${lib.optionalString cfg.lidarr.enable "export LIDARR_API_KEY"}
    ${lib.optionalString cfg.radarr.enable "export RADARR_API_KEY"}
    ${lib.optionalString cfg.sonarr.enable "export SONARR_API_KEY"}
    ${lib.optionalString cfg.prowlarr.enable "export PROWLARR_API_KEY"}
    ${lib.concatMapStrings (dc: ''
      export DC_${sanitize dc.name}_USERNAME
      export DC_${sanitize dc.name}_PASSWORD
    '') (cfg.lidarr.downloadClients ++ cfg.radarr.downloadClients ++ cfg.sonarr.downloadClients)}
    ${lib.concatMapStrings (app: ''
      export APP_${sanitize app.name}_API_KEY
    '') cfg.prowlarr.applications}
    ${lib.concatMapStrings (
      idx:
      lib.optionalString (idx.username != null || idx.usernameFile != null) ''
        export IDX_${sanitize idx.name}_USERNAME
        export IDX_${sanitize idx.name}_PASSWORD
      ''
    ) cfg.prowlarr.indexers}

    # Use envsubst to safely substitute secrets (handles special chars in values).
    # Stage in a private 0600 file: on systemd-user $TMPDIR may be unset and fall
    # back to world-readable /tmp, which would leak decrypted API keys.
    CONFIG_FILE="$(${pkgs.coreutils}/bin/mktemp -t arr-config.XXXXXX.json)"
    trap '${pkgs.coreutils}/bin/rm -f "$CONFIG_FILE"' EXIT
    ${pkgs.coreutils}/bin/chmod 600 "$CONFIG_FILE"
    ${pkgs.envsubst}/bin/envsubst < ${baseConfigTemplate} > "$CONFIG_FILE"

    ${pkgs.arr-mgmt}/bin/arr-mgmt sync \
      --config-file "$CONFIG_FILE" 2>&1 || echo "Warning: *arr sync failed with exit code $?"

    echo "*arr configuration sync completed"
  '';
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

    lidarr = {
      enable = mkEnableOption "Lidarr synchronization";

      baseUrl = mkOption {
        type = types.str;
        default = "http://localhost:8686";
        description = "Lidarr base URL";
      };

      apiKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Lidarr API key (use apiKeyFile for sops secrets)";
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing Lidarr API key";
      };

      bindAddress = mkOption {
        type = types.str;
        example = "192.168.50.4";
        description = "Bind address for Lidarr";
      };

      downloadClients = mkOption {
        type = types.listOf downloadClientSubmodule;
        default = [ ];
        description = "Download clients to configure in Lidarr";
      };

      rootFolders = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "/storage/Data/Music" ];
        description = "Root folders for Lidarr";
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
        assertion = !cfg.lidarr.enable || (cfg.lidarr.apiKey != null) != (cfg.lidarr.apiKeyFile != null);
        message = "Exactly one of 'apiKey' or 'apiKeyFile' must be set for lidarr";
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
    ++ (lib.optionals cfg.lidarr.enable (
      map (dc: {
        assertion = (dc.username != null) != (dc.usernameFile != null);
        message = "Exactly one of 'username' or 'usernameFile' must be set for download client '${dc.name}' in lidarr";
      }) cfg.lidarr.downloadClients
    ))
    ++ (lib.optionals cfg.lidarr.enable (
      map (dc: {
        assertion = (dc.password != null) != (dc.passwordFile != null);
        message = "Exactly one of 'password' or 'passwordFile' must be set for download client '${dc.name}' in lidarr";
      }) cfg.lidarr.downloadClients
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
    ))
    ++ (lib.optionals cfg.prowlarr.enable (
      lib.concatMap (
        idx:
        lib.optionals (idx.username != null || idx.usernameFile != null) [
          {
            assertion = (idx.username != null) != (idx.usernameFile != null);
            message = "Exactly one of 'username' or 'usernameFile' must be set for indexer '${idx.name}'";
          }
          {
            assertion = (idx.password != null) != (idx.passwordFile != null);
            message = "Exactly one of 'password' or 'passwordFile' must be set for indexer '${idx.name}'";
          }
        ]
      ) cfg.prowlarr.indexers
    ));

    # Shared sync script used by both launchd (Darwin) and systemd (Linux)
    local.launchd.services.arr-mgmt = mkIf pkgs.stdenv.isDarwin {
      enable = true;
      keepAlive = false;
      runAtLoad = true;
      waitForSecrets = true;
      command = "${syncScript}";
    };

    systemd.user.services.arr-mgmt = mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "Declarative *arr stack configuration sync";
        After = [
          "network-online.target"
          "sops-nix.service"
        ];
        Wants = [
          "network-online.target"
          "sops-nix.service"
        ];
      };
      Service = {
        Type = "exec";
        ExecStart = "${syncScript}";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
