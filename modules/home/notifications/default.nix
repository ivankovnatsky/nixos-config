{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.notifications;
  parts = splitString ":" cfg.battery.at;
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
      enable = mkEnableOption "daily battery state notifications";

      at = mkOption {
        type = types.strMatching "([01]?[0-9]|2[0-3]):[0-5][0-9]";
        default = "21:00";
        example = "21:00";
        description = ''
          Local time (HH:MM) at which to send the daily battery
          notification. Backed by launchd StartCalendarInterval: if the
          Mac is asleep at the appointed time, the job runs on next
          wake (multiple missed fires coalesce into one).
        '';
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
      runAtLoad = false;
      waitForSecrets = true;

      command =
        let
          script = pkgs.writeShellScript "notifications-battery-run" ''
            set -e
            exec ${pkgs.notifications}/bin/notifications battery \
              --webhook-file ${escapeShellArg cfg.discordWebhookFile}
          '';
        in
        "${script}";

      extraServiceConfig = {
        StartCalendarInterval = [
          {
            Hour = toIntBase10 (elemAt parts 0);
            Minute = toIntBase10 (elemAt parts 1);
          }
        ];
      };
    };
  };
}
