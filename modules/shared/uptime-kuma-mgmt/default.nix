{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.services.uptime-kuma-mgmt;

  monitorSubmodule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        example = "prowlarr";
        description = "Monitor name (must be unique)";
      };

      type = mkOption {
        type = types.enum [ "http" "https" "tcp" "ping" "dns" "postgres" "mqtt" "tailscale-ping" ];
        default = "http";
        description = "Monitor type";
      };

      url = mkOption {
        type = types.str;
        example = "https://example.com";
        description = "URL to monitor";
      };

      interval = mkOption {
        type = types.int;
        default = 60;
        description = "Check interval in seconds";
      };

      maxretries = mkOption {
        type = types.int;
        default = 3;
        description = "Maximum retry attempts";
      };

      retryInterval = mkOption {
        type = types.int;
        default = 60;
        description = "Retry interval in seconds";
      };

      timeout = mkOption {
        type = types.int;
        default = 10;
        description = "Request timeout in seconds";
      };

      expectedStatus = mkOption {
        type = types.int;
        default = 200;
        description = "Expected HTTP status code";
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "Monitor description";
      };
    };
  };

  configJson = pkgs.writeText "uptime-kuma-monitors.json" (builtins.toJSON {
    monitors = map (m: {
      name = m.name;
      type = m.type;
      url = m.url;
      interval = m.interval;
      maxretries = m.maxretries;
      retryInterval = m.retryInterval;
      timeout = m.timeout;
      expectedStatus = m.expectedStatus;
      description = m.description;
    }) cfg.monitors;
  });
in
{
  options.local.services.uptime-kuma-mgmt = {
    enable = mkEnableOption "declarative Uptime Kuma monitor synchronization";

    baseUrl = mkOption {
      type = types.str;
      example = "https://uptime.example.com";
      description = "Uptime Kuma base URL";
    };

    username = mkOption {
      type = types.str;
      description = "Uptime Kuma admin username";
    };

    password = mkOption {
      type = types.str;
      description = "Uptime Kuma admin password";
    };

    monitors = mkOption {
      type = types.listOf monitorSubmodule;
      default = [ ];
      description = "Monitors to configure in Uptime Kuma";
    };
  };

  config = mkMerge [
    # Darwin configuration
    (mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
      system.activationScripts.postActivation.text = ''
        echo "Syncing Uptime Kuma monitors..."
        ${pkgs.uptime-kuma-mgmt}/bin/uptime-kuma-mgmt sync \
          --base-url "${cfg.baseUrl}" \
          --username "${cfg.username}" \
          --password "${cfg.password}" \
          --config-file "${configJson}" || echo "Warning: Uptime Kuma sync failed"
      '';
    })

    # NixOS configuration
    (mkIf (cfg.enable && !pkgs.stdenv.isDarwin) {
      system.activationScripts.uptime-kuma-mgmt = {
        text = ''
          echo "Syncing Uptime Kuma monitors..."
          ${pkgs.uptime-kuma-mgmt}/bin/uptime-kuma-mgmt sync \
            --base-url "${cfg.baseUrl}" \
            --username "${cfg.username}" \
            --password "${cfg.password}" \
            --config-file "${configJson}" || echo "Warning: Uptime Kuma sync failed"
        '';
      };
    })
  ];
}
