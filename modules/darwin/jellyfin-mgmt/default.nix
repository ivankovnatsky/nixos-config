{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.services.jellyfin-mgmt;

  # Base config without secrets (for use with apiKeyFile)
  baseConfig = {
    baseUrl = cfg.baseUrl;
    networkConfig = optionalAttrs (cfg.bindAddress != null) {
      localNetworkAddresses = [ cfg.bindAddress ];
    };
    libraries = map
      (lib: {
        name = lib.name;
        type = lib.type;
        paths = lib.paths;
      })
      cfg.libraries;
  };

  # Static config (only used when apiKey is set directly)
  configJson = pkgs.writeText "jellyfin-config.json" (builtins.toJSON (baseConfig // {
    apiKey = cfg.apiKey;
  }));

  # Runtime config generation script (used with apiKeyFile)
  runtimeConfigScript = ''
    TEMP_CONFIG=$(mktemp)
    API_KEY=$(cat ${cfg.apiKeyFile})
    cat > "$TEMP_CONFIG" << 'EOF'
    ${builtins.toJSON baseConfig}
    EOF
    ${pkgs.jq}/bin/jq --arg apiKey "$API_KEY" '. + {apiKey: $apiKey}' "$TEMP_CONFIG"
    rm -f "$TEMP_CONFIG"
  '';
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
      type = types.nullOr types.str;
      default = null;
      description = "Jellyfin API key (use apiKeyFile instead for secrets)";
    };

    apiKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing Jellyfin API key";
    };

    bindAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "192.168.50.4";
      description = "Bind address for Jellyfin (LocalNetworkAddresses)";
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
    assertions = [
      {
        assertion = (cfg.apiKey != null) != (cfg.apiKeyFile != null);
        message = "Exactly one of apiKey or apiKeyFile must be set for jellyfin-mgmt";
      }
    ];

    # Darwin launchd service
    local.launchd.services.jellyfin-mgmt = {
      enable = true;
      keepAlive = false;
      runAtLoad = true;

      command =
        let
          syncScript = pkgs.writeShellScript "jellyfin-mgmt-sync" ''
            set -e

            echo "Syncing Jellyfin configuration..."
            ${if cfg.apiKeyFile != null then ''
              CONFIG_JSON=$(${runtimeConfigScript})
              echo "$CONFIG_JSON" | ${pkgs.jellyfin-mgmt}/bin/jellyfin-mgmt sync --config-file /dev/stdin 2>&1 || echo "Warning: Jellyfin sync failed with exit code $?"
            '' else ''
              ${pkgs.jellyfin-mgmt}/bin/jellyfin-mgmt sync \
                --config-file "${configJson}" 2>&1 || echo "Warning: Jellyfin sync failed with exit code $?"
            ''}

            echo "Jellyfin configuration sync completed"
          '';
        in
        "${syncScript}";
    };
  };
}
