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
      type = types.str;
      description = "API token for Audiobookshelf authentication";
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
  };

  config = mkIf cfg.enable {
    system.activationScripts.audiobookshelf-mgmt = ''
      echo "Syncing Audiobookshelf configuration..."
      ${pkgs.abs-mgmt}/bin/abs-mgmt sync \
        --base-url "${cfg.baseUrl}" \
        --token "${cfg.apiToken}" \
        --config-file "${configJson}" || echo "Warning: Audiobookshelf sync failed"
    '';
  };
}
