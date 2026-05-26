{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.beszel-mgmt;

  # Template with @BASE_URL@ placeholder; base URL is substituted at runtime
  # via jq --rawfile so secret-derived values never appear on jq's argv.
  beszelConfigTemplate = pkgs.writeText "beszel-config-template.json" (
    builtins.toJSON {
      base_url = "@BASE_URL@";
      inherit (cfg) systems;
    }
  );

  syncScript = pkgs.writeShellScript "beszel-mgmt-sync" ''
    set -e
    umask 077

    echo "Updating Beszel systems..."

    STATE_DIR=$(${pkgs.coreutils}/bin/mktemp -d -t beszel-mgmt.XXXXXX)
    ${pkgs.coreutils}/bin/chmod 700 "$STATE_DIR"
    trap '${pkgs.coreutils}/bin/rm -rf "$STATE_DIR"' EXIT
    CONFIG_FILE="$STATE_DIR/config.json"
    URL_FILE="$STATE_DIR/base-url"

    # Build the base URL into a private file (never on argv).
    ${
      if cfg.externalDomainFile != null then
        ''
          ${pkgs.coreutils}/bin/printf 'https://beszel.' > "$URL_FILE"
          ${pkgs.coreutils}/bin/cat "${cfg.externalDomainFile}" >> "$URL_FILE"
        ''
      else
        ''${pkgs.coreutils}/bin/printf '%s' "${cfg.baseUrl}" > "$URL_FILE"''
    }

    ${pkgs.jq}/bin/jq --rawfile url "$URL_FILE" \
      '(.. | strings) |= (split("@BASE_URL@") | join($url | rtrimstr("\n")))' \
      "${beszelConfigTemplate}" > "$CONFIG_FILE"

    # Auth and webhook are read by the CLI from
    # ~/.config/sops-nix/secrets/{beszel-email,beszel-password,discord-webhook-beszel}.
    ${pkgs.beszel-mgmt}/bin/beszel-mgmt sync \
      --config-file "$CONFIG_FILE" 2>&1 || echo "Warning: Beszel update failed with exit code $?"

    echo "Beszel systems update completed"
  '';
in
{
  options.local.services.beszel-mgmt = {
    enable = mkEnableOption "declarative Beszel systems synchronization";

    baseUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Beszel hub base URL (use externalDomainFile for sops secrets)";
    };

    externalDomainFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing external domain (constructs https://beszel.DOMAIN)";
    };

    systems = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "System name";
            };
            host = mkOption {
              type = types.str;
              description = "System host/IP address";
            };
            port = mkOption {
              type = types.str;
              default = "45876";
              description = "System port";
            };
          };
        }
      );
      default = [ ];
      description = "List of systems to sync to Beszel hub";
    };

  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.baseUrl != null) != (cfg.externalDomainFile != null);
        message = "Exactly one of 'baseUrl' or 'externalDomainFile' must be set for beszel-mgmt";
      }
    ];

    local.launchd.services.beszel-mgmt = mkIf pkgs.stdenv.isDarwin {
      enable = true;
      keepAlive = false;
      runAtLoad = true;
      command = "${syncScript}";
    };

    systemd.user.services.beszel-mgmt = mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "Declarative Beszel systems sync";
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
