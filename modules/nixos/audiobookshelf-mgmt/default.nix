{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.services.audiobookshelf-mgmt;

  configJson = pkgs.writeText "audiobookshelf-libraries.json" (builtins.toJSON {
    libraries = map (lib: {
      name = lib.name;
      folders = lib.folders;
      mediaType = lib.mediaType;
    }) cfg.libraries;
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
        };
      });
      default = [ ];
      description = "Libraries to sync to Audiobookshelf instance";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.audiobookshelf-mgmt = ''
      echo "Updating Audiobookshelf libraries..."
      ${pkgs.abs-mgmt}/bin/abs-mgmt sync \
        --base-url "${cfg.baseUrl}" \
        --token "${cfg.apiToken}" \
        --config-file "${configJson}" || echo "Warning: Audiobookshelf library sync failed"
    '';
  };
}
