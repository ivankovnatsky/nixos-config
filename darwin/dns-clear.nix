{ pkgs, ... }:

{
  local.launchd.services.scheduled-dns-clear = {
    enable = true;
    runAtLoad = false;
    keepAlive = false;
    command = "${pkgs.dns}/bin/dns clear";

    extraServiceConfig = {
      StartCalendarInterval = {
        Hour = 22;
        Minute = 30;
      };
    };
  };
}
