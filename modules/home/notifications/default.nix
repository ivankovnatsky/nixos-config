{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.notifications;
in
{
  options.local.services.notifications = {
    discordWebhookFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to a file containing a Discord webhook URL, shared by all
        notification features that target Discord.
      '';
    };

    battery = {
      enable = mkEnableOption "periodic battery state notifications";

      interval = mkOption {
        type = types.int;
        default = 30 * 60;
        description = "Interval in seconds between battery notifications (default: 30 minutes).";
      };

      runAtLoad = mkOption {
        type = types.bool;
        default = false;
        description = "Send a battery notification immediately when the launchd job is loaded.";
      };
    };
  };

  config = mkIf cfg.battery.enable {
    assertions = [
      {
        assertion = cfg.discordWebhookFile != null;
        message = ''
          local.services.notifications.battery.enable requires
          local.services.notifications.discordWebhookFile to be set.
        '';
      }
    ];

    local.launchd.services.notifications-battery = {
      enable = true;
      keepAlive = false;
      inherit (cfg.battery) runAtLoad;
      waitForSecrets = true;

      command =
        let
          script = pkgs.writeShellScript "notifications-battery-run" ''
            set -e
            exec ${pkgs.notifications}/bin/notifications battery \
              --webhook-file "${cfg.discordWebhookFile}"
          '';
        in
        "${script}";

      extraServiceConfig = {
        StartInterval = cfg.battery.interval;
      };
    };
  };
}
