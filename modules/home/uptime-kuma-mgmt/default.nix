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

    # Single 0700 tempdir for transient secret-bearing files. Trap covers
    # the whole dir before any secret touches disk.
    STATE_DIR=$(${pkgs.coreutils}/bin/mktemp -d -t uptime-kuma-mgmt.XXXXXX)
    ${pkgs.coreutils}/bin/chmod 700 "$STATE_DIR"
    trap '${pkgs.coreutils}/bin/rm -rf "$STATE_DIR"' EXIT

    # Sops file paths for jq --rawfile (path is on argv but content isn't).
    # /dev/null is used as a no-op fallback so jq always has a readable path.
    EXTERNAL_DOMAIN_FILE=/dev/null
    POSTGRES_PASSWORD_FILE=/dev/null
    ${optionalString (
      cfg.externalDomainFile != null
    ) ''EXTERNAL_DOMAIN_FILE="${cfg.externalDomainFile}"''}
    ${optionalString (
      cfg.postgresPasswordFile != null
    ) ''POSTGRES_PASSWORD_FILE="${cfg.postgresPasswordFile}"''}

    # Resolve base URL. The @EXTERNAL_DOMAIN@ substitution is done via a
    # sed script file (in STATE_DIR) so the sops value never appears on
    # sed's argv. tr strips the trailing newline sops files carry.
    ${
      if cfg.baseUrlFile != null then
        ''BASE_URL=$(${pkgs.coreutils}/bin/cat "${cfg.baseUrlFile}")''
      else
        ''
          SED_SCRIPT="$STATE_DIR/base-url.sed"
          {
            ${pkgs.coreutils}/bin/printf 's|@EXTERNAL_DOMAIN@|'
            ${pkgs.coreutils}/bin/tr -d '\n' < "$EXTERNAL_DOMAIN_FILE"
            ${pkgs.coreutils}/bin/printf '|g\n'
          } > "$SED_SCRIPT"
          BASE_URL=$(echo "${cfg.baseUrl}" | ${pkgs.gnused}/bin/sed -f "$SED_SCRIPT")
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

    # Create runtime config with substituted placeholders. Lives in STATE_DIR
    # (already trapped). Secrets are read via jq --rawfile so the values
    # never appear on jq's argv. rtrimstr strips the trailing newline.
    RUNTIME_CONFIG="$STATE_DIR/monitors.json"
    ${pkgs.jq}/bin/jq \
      --rawfile ext "$EXTERNAL_DOMAIN_FILE" \
      --rawfile pwd "$POSTGRES_PASSWORD_FILE" \
      '(.. | strings) |= (split("@EXTERNAL_DOMAIN@") | join($ext | rtrimstr("\n")) | split("@POSTGRES_PASSWORD@") | join($pwd | rtrimstr("\n")))' \
      "${configJsonTemplate}" > "$RUNTIME_CONFIG"

    # Auth (username/password) and discord webhook are read by the CLI from
    # ~/.config/sops-nix/secrets/{uptime-kuma-username,uptime-kuma-password,discord-webhook-kuma}.
    # base-url is not a credential, so it's fine on argv.
    ${
      if !cfg.notifications.enable then
        ''
          ${pkgs.uptime-kuma-mgmt}/bin/uptime-kuma-mgmt sync \
            --base-url "$BASE_URL" \
            --config-file "$RUNTIME_CONFIG" \
            --no-notifications 2>&1 || echo "Warning: Uptime Kuma sync failed with exit code $?"
        ''
      else
        ''
          ${pkgs.uptime-kuma-mgmt}/bin/uptime-kuma-mgmt sync \
            --base-url "$BASE_URL" \
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
        Type = "exec";
        ExecStart = "${syncScript}";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
