{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.prevent-sleep;

  settingsPackage = pkgs.callPackage ../../../packages/settings { };

  # Wrapper to check if already running
  preventSleepWrapper = pkgs.writeScriptBin "prevent-sleep-wrapper" ''
    #!${pkgs.bash}/bin/bash

    # Check if caffeinate is already running with our specific flags
    if /usr/bin/pgrep -f "caffeinate.*-d.*-i.*-m.*-s.*-t.*43200" > /dev/null; then
        echo "prevent-sleep is already running, skipping..."
        exit 0
    fi

    # Start prevent-sleep via settings awake
    exec ${settingsPackage}/bin/settings awake
  '';
in
{
  options.local.services.prevent-sleep = {
    enable = mkEnableOption "prevent-sleep service";

    workHours = mkOption {
      type = types.listOf types.int;
      default = [
        9
        10
        11
        12
        13
        14
        15
        16
        17
      ];
      description = "Hours during which to prevent sleep";
    };

    workDays = mkOption {
      type = types.listOf types.int;
      default = [
        1
        2
        3
        4
        5
      ]; # Monday-Friday
      description = "Days of week to prevent sleep (1=Monday, 7=Sunday)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ settingsPackage ];

    local.launchd.services.prevent-sleep = {
      enable = true;
      type = "user-agent";
      runAtLoad = false;
      keepAlive = false;

      command = "${preventSleepWrapper}/bin/prevent-sleep-wrapper";

      extraServiceConfig = {
        StartCalendarInterval = builtins.concatMap (hour:
          map (weekday: {
            Hour = hour;
            Minute = 0;
            Weekday = weekday;
          }) cfg.workDays) cfg.workHours;
      };
    };
  };
}
