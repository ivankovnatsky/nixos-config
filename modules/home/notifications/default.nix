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
        default = 15 * 60;
        description = ''
          Launchd polling interval in seconds. The script itself decides
          whether to actually send (see dailyAt / belowPercent), so this
          only bounds how soon a condition is detected.
        '';
      };

      runAtLoad = mkOption {
        type = types.bool;
        default = false;
        description = "Run the battery notifier immediately when the launchd job is loaded.";
      };

      dailyAt = mkOption {
        type = types.str;
        default = "";
        example = "21:00";
        description = ''
          Send a daily battery notification at or after this HH:MM (local
          time), once per day. Empty string disables the daily slot.
        '';
      };

      belowPercent = mkOption {
        type = types.int;
        default = 0;
        example = 50;
        description = ''
          Send an extra notification when the battery is at or below this
          percentage and discharging. 0 disables low-battery alerts.
        '';
      };

      lowIntervalHours = mkOption {
        type = types.numbers.positive;
        default = 3;
        description = "Minimum hours between repeated low-battery notifications.";
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
              --webhook-file ${escapeShellArg cfg.discordWebhookFile} \
              --daily-at ${escapeShellArg cfg.battery.dailyAt} \
              --below-percent ${toString cfg.battery.belowPercent} \
              --low-interval-hours ${toString cfg.battery.lowIntervalHours}
          '';
        in
        "${script}";

      extraServiceConfig = {
        StartInterval = cfg.battery.interval;
      };
    };
  };
}
