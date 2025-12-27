{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.local.services.scheduled-shutdown;
in
{
  options.local.services.scheduled-shutdown = {
    enable = mkEnableOption "forced scheduled shutdown using launchd";

    hour = mkOption {
      type = types.int;
      default = 22;
      description = "Hour to shutdown (0-23)";
    };

    minute = mkOption {
      type = types.int;
      default = 30;
      description = "Minute to shutdown (0-59)";
    };
  };

  config = mkIf cfg.enable {
    local.launchd.services.scheduled-shutdown = {
      enable = true;
      type = "daemon";
      runAtLoad = false;
      keepAlive = false;
      command = "/sbin/shutdown -h now";

      extraServiceConfig = {
        StartCalendarInterval = {
          Hour = cfg.hour;
          Minute = cfg.minute;
        };
      };
    };
  };
}
