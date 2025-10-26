{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.services.audiobookshelf-mgmt;

  configJson = pkgs.writeText "audiobookshelf-config.json" (builtins.toJSON {
    libraries = map (lib: {
      name = lib.name;
      folders = lib.folders;
      mediaType = lib.mediaType;
      provider = lib.provider;
    }) cfg.libraries;
    users = map (user: {
      username = user.username;
      password = user.password;
      type = user.type;
      libraries = user.libraries;
    }) cfg.users;
  });
in
{
  options.local.services.audiobookshelf-mgmt = {
    enable = mkEnableOption "declarative Audiobookshelf library synchronization";

    baseUrl = mkOption {
      type = types.str;
      default = "http://localhost:8000";
      description = "Audiobookshelf instance base URL";
    };

    apiToken = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "API token for Audiobookshelf authentication";
    };

    apiTokenFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/audiobookshelf-api-token";
      description = "Path to file containing API token for Audiobookshelf authentication";
    };

    libraries = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            example = "Podcasts";
            description = "Library name";
          };

          folders = mkOption {
            type = types.listOf types.str;
            example = [ "/mnt/mac/Volumes/Storage/Data/media/podcasts" ];
            description = "List of folder paths for this library";
          };

          mediaType = mkOption {
            type = types.enum [ "book" "podcast" ];
            default = "podcast";
            description = "Media type for this library";
          };

          provider = mkOption {
            type = types.enum [ "google" "itunes" "audible" "audnexus" ];
            default = "itunes";
            description = "Metadata provider for this library";
          };
        };
      });
      default = [ ];
      description = "Libraries to sync to Audiobookshelf instance";
    };

    users = mkOption {
      type = types.listOf (types.submodule {
        options = {
          username = mkOption {
            type = types.str;
            example = "textcast";
            description = "Username for the user account";
          };

          password = mkOption {
            type = types.str;
            description = "Password for the user account (only used during creation)";
          };

          type = mkOption {
            type = types.enum [ "root" "admin" "user" "guest" ];
            default = "user";
            description = "User account type";
          };

          libraries = mkOption {
            type = types.listOf types.str;
            default = [ ];
            example = [ ];
            description = "List of library IDs the user can access (empty = all libraries)";
          };
        };
      });
      default = [ ];
      description = "Users to sync to Audiobookshelf instance";
    };

    opmlSync = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          enable = mkEnableOption "automatic OPML synchronization from Podsync";

          opmlUrl = mkOption {
            type = types.str;
            example = "https://podsync.example.com/podsync.opml";
            description = "URL to fetch OPML file from (e.g., Podsync)";
          };

          libraryName = mkOption {
            type = types.str;
            default = "Podcasts";
            description = "Target library name for podcast imports (library and folder IDs auto-detected)";
          };

          autoDownload = mkOption {
            type = types.bool;
            default = true;
            description = "Enable automatic episode downloads for imported podcasts";
          };

          interval = mkOption {
            type = types.str;
            default = "hourly";
            description = "Systemd timer interval (e.g., 'hourly', 'daily', '*:0/15' for every 15 min)";
          };
        };
      });
      default = null;
      description = "OPML synchronization configuration (e.g., from Podsync)";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.apiToken != null) != (cfg.apiTokenFile != null);
        message = "Exactly one of apiToken or apiTokenFile must be set for audiobookshelf-mgmt";
      }
    ];

    # Use systemd service instead of activation script when using file-based secrets
    # to ensure proper ordering with sops-nix secret installation
    system.activationScripts.audiobookshelf-mgmt = mkIf (cfg.apiTokenFile == null) ''
      echo "Syncing Audiobookshelf configuration..."
      ${pkgs.abs-mgmt}/bin/abs-mgmt sync \
        --base-url "${cfg.baseUrl}" \
        --token "${cfg.apiToken}" \
        --config-file "${configJson}" || echo "Warning: Audiobookshelf sync failed"
    '';

    systemd.services.audiobookshelf-mgmt-sync = mkIf (cfg.apiTokenFile != null) {
      description = "Audiobookshelf configuration synchronization";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        ExecStart = pkgs.writeShellScript "audiobookshelf-mgmt-sync" ''
          echo "Syncing Audiobookshelf configuration..."
          ${pkgs.abs-mgmt}/bin/abs-mgmt sync \
            --base-url "${cfg.baseUrl}" \
            --token "$(cat ${cfg.apiTokenFile})" \
            --config-file "${configJson}" || echo "Warning: Audiobookshelf sync failed"
        '';
      };
    };

    # OPML sync service and timer
    systemd.services.audiobookshelf-opml-sync = mkIf (cfg.opmlSync != null && cfg.opmlSync.enable) (
      let
        tokenArg = if cfg.apiTokenFile != null
          then ''"$(cat ${cfg.apiTokenFile})"''
          else cfg.apiToken;
      in {
        description = "Audiobookshelf OPML synchronization from Podsync";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.abs-mgmt}/bin/abs-mgmt sync-opml --base-url ${cfg.baseUrl} --token ${tokenArg} --opml-url ${cfg.opmlSync.opmlUrl} --library-name ${cfg.opmlSync.libraryName}${optionalString cfg.opmlSync.autoDownload " --auto-download"}";
          User = "root";
        };
      }
    );

    systemd.timers.audiobookshelf-opml-sync = mkIf (cfg.opmlSync != null && cfg.opmlSync.enable) {
      description = "Timer for Audiobookshelf OPML synchronization";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.opmlSync.interval;
        Persistent = true;
        RandomizedDelaySec = "5min";
      };
    };
  };
}
