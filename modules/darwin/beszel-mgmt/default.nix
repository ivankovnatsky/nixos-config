{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.beszel-mgmt;

  beszelConfig = pkgs.writeText "beszel-systems.json" (builtins.toJSON {
    systems = cfg.systems;
  });
in
{
  options.local.services.beszel-mgmt = {
    enable = mkEnableOption "declarative Beszel systems synchronization";

    baseUrl = mkOption {
      type = types.str;
      default = "https://beszel.${config.secrets.externalDomain}";
      description = "Beszel hub base URL";
    };

    email = mkOption {
      type = types.str;
      description = "Beszel hub email for authentication";
    };

    password = mkOption {
      type = types.str;
      description = "Beszel hub password for authentication";
    };

    systems = mkOption {
      type = types.listOf (types.submodule {
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
      });
      default = [ ];
      description = "List of systems to sync to Beszel hub";
    };

    discordWebhook = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Discord webhook URL for notifications (optional)";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.postActivation.text = ''
      echo "Updating Beszel systems..."
      ${pkgs.beszel-mgmt}/bin/beszel-mgmt sync \
        --base-url "${cfg.baseUrl}" \
        --email "${cfg.email}" \
        --password "${cfg.password}" \
        --config-file "${beszelConfig}" \
        ${optionalString (cfg.discordWebhook != null) ''--discord-webhook "${cfg.discordWebhook}"''} || echo "Warning: Beszel update failed"
    '';
  };
}
