{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.healthchecks-mgmt;

  checksConfig = pkgs.writeText "healthchecks-checks.json" (
    builtins.toJSON {
      checks = map (c: {
        inherit (c)
          name
          slug
          tags
          timeout
          grace
          channels
          ;
      }) cfg.checks;
    }
  );
in
{
  options.local.services.healthchecks-mgmt = {
    enable = mkEnableOption "declarative healthchecks.io check synchronization";

    apiKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "healthchecks.io API key (use apiKeyFile for sops secrets)";
    };

    apiKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing healthchecks.io API key";
    };

    apiUrl = mkOption {
      type = types.str;
      default = "https://healthchecks.io";
      description = "healthchecks.io API base URL";
    };

    checks = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Check name (must be unique, used for reconciliation)";
            };
            slug = mkOption {
              type = types.str;
              description = "URL-friendly identifier";
            };
            tags = mkOption {
              type = types.str;
              default = "";
              description = "Space-separated tags";
            };
            timeout = mkOption {
              type = types.int;
              default = 86400;
              description = "Expected period in seconds";
            };
            grace = mkOption {
              type = types.int;
              default = 3600;
              description = "Grace period in seconds";
            };
            channels = mkOption {
              type = types.str;
              default = "*";
              description = "Channels to notify (* = all integrations)";
            };
          };
        }
      );
      default = [ ];
      description = "List of checks to sync to healthchecks.io";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.apiKey != null) != (cfg.apiKeyFile != null);
        message = "Exactly one of 'apiKey' or 'apiKeyFile' must be set for healthchecks-mgmt";
      }
    ];

    local.launchd.services.healthchecks-mgmt = {
      enable = true;
      keepAlive = false;
      runAtLoad = true;

      command =
        let
          syncScript = pkgs.writeShellScript "healthchecks-mgmt-sync" ''
            set -e

            echo "Syncing healthchecks.io checks..."

            ${
              if cfg.apiKeyFile != null then
                ''
                  API_KEY="$(cat ${cfg.apiKeyFile})"
                ''
              else
                ''
                  API_KEY="${cfg.apiKey}"
                ''
            }

            ${pkgs.healthchecks-mgmt}/bin/healthchecks-mgmt \
              --api-key "$API_KEY" \
              --api-url "${cfg.apiUrl}" \
              sync \
              --config-file "${checksConfig}" 2>&1 || echo "Warning: healthchecks-mgmt sync failed with exit code $?"

            echo "healthchecks.io sync completed"
          '';
        in
        "${syncScript}";
    };
  };
}
