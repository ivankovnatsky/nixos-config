{ pkgs, ... }:
{
  local.launchd.services.auto-poweroff = {
    enable = true;
    command = "${pkgs.homelab}/bin/homelab auto-shutdown";
    runAtLoad = false;
    keepAlive = false;
    extraServiceConfig = {
      StartCalendarInterval = {
        Hour = 22;
        Minute = 20;
      };
    };
  };

  local.launchd.services.auto-poweroff-notify = {
    enable = true;
    command = "${pkgs.homelab}/bin/homelab auto-notify";
    runAtLoad = false;
    keepAlive = false;
    extraServiceConfig = {
      StartCalendarInterval = {
        Hour = 22;
        Minute = 10;
      };
    };
  };
}
