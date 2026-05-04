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
    battery = {
      enable = mkEnableOption "periodic battery state notifications to Discord";

      interval = mkOption {
        type = types.int;
        default = 30 * 60;
        description = "Interval in seconds between battery notifications (default: 30 minutes)";
      };

      runAtLoad = mkOption {
        type = types.bool;
        default = false;
        description = "Send a notification immediately when the launchd job is loaded.";
      };

      discordWebhookFile = mkOption {
        type = types.path;
        description = "Path to file containing the Discord webhook URL.";
      };
    };
  };

  config = mkIf cfg.battery.enable {
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
              --webhook-file "${cfg.battery.discordWebhookFile}"
          '';
        in
        "${script}";

      extraServiceConfig = {
        StartInterval = cfg.battery.interval;
      };
    };
  };
}
