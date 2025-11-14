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

  # Template JSON with placeholders (to be substituted at runtime)
  configJsonTemplate = pkgs.writeText "uptime-kuma-monitors-template.json" (builtins.toJSON {
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
      type = types.nullOr types.str;
      default = null;
      example = "https://uptime.example.com";
      description = "Uptime Kuma base URL (use baseUrlFile for sops secrets)";
    };

    baseUrlFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing Uptime Kuma base URL (alternative to baseUrl)";
    };

    username = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Uptime Kuma admin username (use usernameFile for sops secrets)";
    };

    usernameFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing Uptime Kuma admin username (alternative to username)";
    };

    password = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Uptime Kuma admin password (use passwordFile for sops secrets)";
    };

    passwordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing Uptime Kuma admin password (alternative to password)";
    };

    monitors = mkOption {
      type = types.listOf monitorSubmodule;
      default = [ ];
      description = "Monitors to configure in Uptime Kuma";
    };

    discordWebhook = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Discord webhook URL for notifications (optional)";
    };

    discordWebhookFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing Discord webhook URL (alternative to discordWebhook)";
    };

    interval = mkOption {
      type = types.int;
      default = 86400;
      description = "Sync interval in seconds (default: 86400 = once per day)";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.baseUrl != null && cfg.baseUrlFile == null) || (cfg.baseUrl == null && cfg.baseUrlFile != null);
        message = "Either baseUrl or baseUrlFile must be set, but not both";
      }
      {
        assertion = (cfg.username != null && cfg.usernameFile == null) || (cfg.username == null && cfg.usernameFile != null);
        message = "Either username or usernameFile must be set, but not both";
      }
      {
        assertion = (cfg.password != null && cfg.passwordFile == null) || (cfg.password == null && cfg.passwordFile != null);
        message = "Either password or passwordFile must be set, but not both";
      }
      {
        assertion = (cfg.discordWebhook == null && cfg.discordWebhookFile == null) ||
                    (cfg.discordWebhook != null && cfg.discordWebhookFile == null) ||
                    (cfg.discordWebhook == null && cfg.discordWebhookFile != null);
        message = "Either discordWebhook or discordWebhookFile can be set, but not both";
      }
    ];

    # Darwin launchd service
    local.launchd.services.uptime-kuma-mgmt = {
      enable = true;
      keepAlive = false;
      runAtLoad = true;

        command = let
          syncScript = pkgs.writeShellScript "uptime-kuma-mgmt-sync" ''
            set -e

            echo "Syncing Uptime Kuma monitors..."

            # Read additional secrets for placeholder substitution
            EXTERNAL_DOMAIN=$(cat /run/secrets/external-domain)
            POSTGRES_PASSWORD=$(cat /run/secrets/postgres-monitoring-password)

            # Read secrets from files or use direct values (with runtime substitution)
            ${if cfg.baseUrlFile != null then ''
              BASE_URL=$(cat "${cfg.baseUrlFile}")
            '' else ''
              BASE_URL=$(echo "${cfg.baseUrl}" | sed "s|@EXTERNAL_DOMAIN@|$EXTERNAL_DOMAIN|g")
            ''}
            ${if cfg.usernameFile != null then ''
              USERNAME=$(cat "${cfg.usernameFile}")
            '' else ''
              USERNAME="${cfg.username}"
            ''}
            ${if cfg.passwordFile != null then ''
              PASSWORD=$(cat "${cfg.passwordFile}")
            '' else ''
              PASSWORD="${cfg.password}"
            ''}

            # Create runtime config with substituted placeholders
            RUNTIME_CONFIG="/tmp/uptime-kuma-monitors-$$.json"
            sed "s|@EXTERNAL_DOMAIN@|$EXTERNAL_DOMAIN|g" "${configJsonTemplate}" | \
              sed "s|@POSTGRES_PASSWORD@|$POSTGRES_PASSWORD|g" | \

            # Build command with optional Discord webhook
            ${if cfg.discordWebhook != null || cfg.discordWebhookFile != null then ''
              ${if cfg.discordWebhookFile != null then ''
                DISCORD_WEBHOOK=$(cat "${cfg.discordWebhookFile}")
              '' else ''
                DISCORD_WEBHOOK="${cfg.discordWebhook}"
              ''}
              ${pkgs.uptime-kuma-mgmt}/bin/uptime-kuma-mgmt sync \
                --base-url "$BASE_URL" \
                --username "$USERNAME" \
                --password "$PASSWORD" \
                --config-file "$RUNTIME_CONFIG" \
                --discord-webhook "$DISCORD_WEBHOOK" 2>&1 || echo "Warning: Uptime Kuma sync failed with exit code $?"
            '' else ''
              ${pkgs.uptime-kuma-mgmt}/bin/uptime-kuma-mgmt sync \
                --base-url "$BASE_URL" \
                --username "$USERNAME" \
                --password "$PASSWORD" \
                --config-file "$RUNTIME_CONFIG" 2>&1 || echo "Warning: Uptime Kuma sync failed with exit code $?"
            ''}

            # Cleanup runtime config
            rm -f "$RUNTIME_CONFIG"

            echo "Uptime Kuma sync completed"
          '';
        in "${syncScript}";
    };
  };
}
