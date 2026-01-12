{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.beszel-mgmt;

  beszelConfig = pkgs.writeText "beszel-systems.json" (
    builtins.toJSON {
      systems = cfg.systems;
    }
  );
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

    email = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Beszel hub email for authentication (use emailFile for sops secrets)";
    };

    emailFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing Beszel hub email";
    };

    password = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Beszel hub password for authentication (use passwordFile for sops secrets)";
    };

    passwordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing Beszel hub password";
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

    discordWebhook = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Discord webhook URL for notifications (use discordWebhookFile for sops secrets)";
    };

    discordWebhookFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing Discord webhook URL";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.baseUrl != null) != (cfg.externalDomainFile != null);
        message = "Exactly one of 'baseUrl' or 'externalDomainFile' must be set for beszel-mgmt";
      }
      {
        assertion = (cfg.email != null) != (cfg.emailFile != null);
        message = "Exactly one of 'email' or 'emailFile' must be set for beszel-mgmt";
      }
      {
        assertion = (cfg.password != null) != (cfg.passwordFile != null);
        message = "Exactly one of 'password' or 'passwordFile' must be set for beszel-mgmt";
      }
      {
        assertion =
          (cfg.discordWebhook == null && cfg.discordWebhookFile == null)
          || (cfg.discordWebhook != null) != (cfg.discordWebhookFile != null);
        message = "At most one of 'discordWebhook' or 'discordWebhookFile' can be set for beszel-mgmt";
      }
    ];

    local.launchd.services.beszel-mgmt = {
      enable = true;
      keepAlive = false;
      runAtLoad = true;

      command =
        let
          syncScript = pkgs.writeShellScript "beszel-mgmt-sync" ''
            set -e

            echo "Updating Beszel systems..."

            # Read secrets from files at runtime (keeps secrets out of /nix/store)
            ${
              if cfg.externalDomainFile != null then
                ''
                  EXTERNAL_DOMAIN="$(cat ${cfg.externalDomainFile})"
                  BASE_URL="https://beszel.$EXTERNAL_DOMAIN"
                ''
              else
                ''
                  BASE_URL="${cfg.baseUrl}"
                ''
            }
            BESZEL_EMAIL="${if cfg.emailFile != null then "$(cat ${cfg.emailFile})" else cfg.email}"
            BESZEL_PASSWORD="${if cfg.passwordFile != null then "$(cat ${cfg.passwordFile})" else cfg.password}"
            ${optionalString (cfg.discordWebhookFile != null) ''
              DISCORD_WEBHOOK="$(cat ${cfg.discordWebhookFile})"
            ''}
            ${optionalString (cfg.discordWebhook != null) ''
              DISCORD_WEBHOOK="${cfg.discordWebhook}"
            ''}

            ${pkgs.beszel-mgmt}/bin/beszel-mgmt sync \
              --base-url "$BASE_URL" \
              --email "$BESZEL_EMAIL" \
              --password "$BESZEL_PASSWORD" \
              --config-file "${beszelConfig}" \
              ${
                optionalString (
                  cfg.discordWebhook != null || cfg.discordWebhookFile != null
                ) ''--discord-webhook "$DISCORD_WEBHOOK"''
              } 2>&1 || echo "Warning: Beszel update failed with exit code $?"

            echo "Beszel systems update completed"
          '';
        in
        "${syncScript}";
    };
  };
}
