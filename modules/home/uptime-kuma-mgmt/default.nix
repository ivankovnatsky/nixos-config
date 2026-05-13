{
  config,
  lib,
  pkgs,
  ...
}:

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
        type = types.enum [
          "http"
          "https"
          "tcp"
          "ping"
          "dns"
          "postgres"
          "mqtt"
          "tailscale-ping"
        ];
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

      maxredirects = mkOption {
        type = types.int;
        default = 10;
        description = "Maximum number of redirects to follow (0 disables following redirects)";
      };

      timeout = mkOption {
        type = types.int;
        default = 10;
        description = "Request timeout in seconds";
      };

      expectedStatus = mkOption {
        type = types.either types.int (types.listOf types.str);
        default = 200;
        example = [
          "200-299"
          "302"
        ];
        description = ''
          Expected HTTP status code(s). Either a single integer (e.g. 302)
          or a list of code/range strings (e.g. [ "200-299" "302" ]).
        '';
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "Monitor description";
      };
    };
  };

  # Template JSON with placeholders (to be substituted at runtime)
  configJsonTemplate = pkgs.writeText "uptime-kuma-monitors-template.json" (
    builtins.toJSON {
      monitors = map (m: {
        inherit (m) name;
        inherit (m) type;
        inherit (m) url;
        inherit (m) interval;
        inherit (m) maxretries;
        inherit (m) retryInterval;
        inherit (m) maxredirects;
        inherit (m) timeout;
        inherit (m) expectedStatus;
        inherit (m) description;
      }) cfg.monitors;
    }
  );

  syncScript = pkgs.writeShellScript "uptime-kuma-mgmt-sync" ''
    set -e
    umask 077

    echo "Syncing Uptime Kuma monitors..."

    # Read additional secrets for placeholder substitution
    ${optionalString (
      cfg.externalDomainFile != null
    ) ''EXTERNAL_DOMAIN=$(${pkgs.coreutils}/bin/cat "${cfg.externalDomainFile}")''}
    ${optionalString (
      cfg.postgresPasswordFile != null
    ) ''POSTGRES_PASSWORD=$(${pkgs.coreutils}/bin/cat "${cfg.postgresPasswordFile}")''}
    EXTERNAL_DOMAIN=''${EXTERNAL_DOMAIN:-}
    POSTGRES_PASSWORD=''${POSTGRES_PASSWORD:-}

    # Read secrets from files or use direct values (with runtime substitution)
    ${
      if cfg.baseUrlFile != null then
        ''
          BASE_URL=$(${pkgs.coreutils}/bin/cat "${cfg.baseUrlFile}")
        ''
      else
        ''
          BASE_URL=$(echo "${cfg.baseUrl}" | ${pkgs.gnused}/bin/sed "s|@EXTERNAL_DOMAIN@|$EXTERNAL_DOMAIN|g")
        ''
    }
    ${
      if cfg.usernameFile != null then
        ''
          USERNAME=$(${pkgs.coreutils}/bin/cat "${cfg.usernameFile}")
        ''
      else
        ''
          USERNAME="${cfg.username}"
        ''
    }
    ${
      if cfg.passwordFile != null then
        ''
          PASSWORD=$(${pkgs.coreutils}/bin/cat "${cfg.passwordFile}")
        ''
      else
        ''
          PASSWORD="${cfg.password}"
        ''
    }

    # Wait for the Kuma server to accept connections before syncing.
    # On boot, the mgmt unit can fire before Kuma has bound its port;
    # without this loop the sync would fail and (since failures are
    # tolerated) silently leave monitors unsynced until the next trigger.
    echo "Waiting for $BASE_URL to become ready..."
    READY=0
    for _ in $(${pkgs.coreutils}/bin/seq 180); do
      if ${pkgs.curl}/bin/curl -fsS -o /dev/null --connect-timeout 2 "$BASE_URL"; then
        echo "Kuma is ready."
        READY=1
        break
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done
    if [ "$READY" -ne 1 ]; then
      echo "Warning: $BASE_URL did not become ready within 180s; sync will likely fail"
    fi

    # Create runtime config with substituted placeholders
    RUNTIME_CONFIG=$(${pkgs.coreutils}/bin/mktemp -t uptime-kuma-monitors.XXXXXX)
    trap '${pkgs.coreutils}/bin/rm -f "$RUNTIME_CONFIG"' EXIT
    ${pkgs.gnused}/bin/sed "s|@EXTERNAL_DOMAIN@|$EXTERNAL_DOMAIN|g" "${configJsonTemplate}" | \
      ${pkgs.gnused}/bin/sed "s|@POSTGRES_PASSWORD@|$POSTGRES_PASSWORD|g" > "$RUNTIME_CONFIG"

    # Build command based on notifications.enable and webhook config.
    # When notifications are disabled, sync with --no-notifications so
    # the existing Discord notification is removed.
    ${
      if !cfg.notifications.enable then
        ''
          ${pkgs.uptime-kuma-mgmt}/bin/uptime-kuma-mgmt sync \
            --base-url "$BASE_URL" \
            --username "$USERNAME" \
            --password "$PASSWORD" \
            --config-file "$RUNTIME_CONFIG" \
            --no-notifications 2>&1 || echo "Warning: Uptime Kuma sync failed with exit code $?"
        ''
      else if cfg.discordWebhook != null || cfg.discordWebhookFile != null then
        ''
          ${
            if cfg.discordWebhookFile != null then
              ''
                DISCORD_WEBHOOK=$(${pkgs.coreutils}/bin/cat "${cfg.discordWebhookFile}")
              ''
            else
              ''
                DISCORD_WEBHOOK="${cfg.discordWebhook}"
              ''
          }
          ${pkgs.uptime-kuma-mgmt}/bin/uptime-kuma-mgmt sync \
            --base-url "$BASE_URL" \
            --username "$USERNAME" \
            --password "$PASSWORD" \
            --config-file "$RUNTIME_CONFIG" \
            --discord-webhook "$DISCORD_WEBHOOK" 2>&1 || echo "Warning: Uptime Kuma sync failed with exit code $?"
        ''
      else
        ''
          ${pkgs.uptime-kuma-mgmt}/bin/uptime-kuma-mgmt sync \
            --base-url "$BASE_URL" \
            --username "$USERNAME" \
            --password "$PASSWORD" \
            --config-file "$RUNTIME_CONFIG" 2>&1 || echo "Warning: Uptime Kuma sync failed with exit code $?"
        ''
    }

    echo "Uptime Kuma sync completed"
  '';
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

    notifications.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to manage Discord notifications. When false, the sync command
        deletes the Discord notification (if present) and does not attach any
        notification to monitors.
      '';
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

    externalDomainFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing external domain for placeholder substitution";
    };

    postgresPasswordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing postgres monitoring password for placeholder substitution";
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
        assertion =
          (cfg.baseUrl != null && cfg.baseUrlFile == null)
          || (cfg.baseUrl == null && cfg.baseUrlFile != null);
        message = "Either baseUrl or baseUrlFile must be set, but not both";
      }
      {
        assertion =
          (cfg.username != null && cfg.usernameFile == null)
          || (cfg.username == null && cfg.usernameFile != null);
        message = "Either username or usernameFile must be set, but not both";
      }
      {
        assertion =
          (cfg.password != null && cfg.passwordFile == null)
          || (cfg.password == null && cfg.passwordFile != null);
        message = "Either password or passwordFile must be set, but not both";
      }
      {
        assertion =
          (cfg.discordWebhook == null && cfg.discordWebhookFile == null)
          || (cfg.discordWebhook != null && cfg.discordWebhookFile == null)
          || (cfg.discordWebhook == null && cfg.discordWebhookFile != null);
        message = "Either discordWebhook or discordWebhookFile can be set, but not both";
      }
    ];

    local.launchd.services.uptime-kuma-mgmt = mkIf pkgs.stdenv.isDarwin {
      enable = true;
      keepAlive = false;
      runAtLoad = true;
      command = "${syncScript}";
    };

    systemd.user.services.uptime-kuma-mgmt = mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "Uptime Kuma declarative monitor sync";
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
        Type = "oneshot";
        ExecStart = "${syncScript}";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
