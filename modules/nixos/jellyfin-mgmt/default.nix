{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.services.jellyfin-mgmt;

  configJson = pkgs.writeText "jellyfin-config.json" (builtins.toJSON {
    baseUrl = cfg.baseUrl;
    apiKey = cfg.apiKey;
    libraries = map (lib: {
      name = lib.name;
      type = lib.type;
      paths = lib.paths;
    }) cfg.libraries;
  });
in
{
  options.local.services.jellyfin-mgmt = {
    enable = mkEnableOption "declarative Jellyfin configuration synchronization";

    baseUrl = mkOption {
      type = types.str;
      default = "http://localhost:8096";
      description = "Jellyfin base URL";
    };

    apiKey = mkOption {
      type = types.str;
      description = "Jellyfin API key";
    };

    libraries = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            example = "Movies";
            description = "Library name";
          };

          type = mkOption {
            type = types.enum [ "movies" "tvshows" "music" "books" "photos" ];
            default = "movies";
            description = "Library type";
          };

          paths = mkOption {
            type = types.listOf types.str;
            example = [ "/var/lib/jellyfin/media/movies" ];
            description = "Media paths for this library";
          };
        };
      });
      default = [ ];
      description = "Jellyfin libraries to manage";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.jellyfin-mgmt = ''
      echo "Syncing Jellyfin configuration..."
      ${pkgs.jellyfin-mgmt}/bin/jellyfin-mgmt sync \
        --config-file "${configJson}" || echo "Warning: Jellyfin sync failed"
    '';
  };
}
