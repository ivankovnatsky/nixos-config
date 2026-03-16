{ pkgs, ... }:
{
  local.launchd.services.mas-upgrade = {
    enable = true;
    command = "${pkgs.mas}/bin/mas upgrade";
    keepAlive = false;
    runAtLoad = false;
    extraServiceConfig = {
      StartCalendarInterval = [{ Day = 1; Hour = 9; Minute = 0; }];
    };
  };
}
