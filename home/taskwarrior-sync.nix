{ pkgs, ... }:
{
  local.launchd.services.taskwarrior-sync = {
    enable = true;
    keepAlive = false;
    runAtLoad = false;
    command = "${pkgs.taskwarrior3}/bin/task rc.verbose=sync sync";
    extraServiceConfig = {
      StartInterval = 60 * 15; # 15m
    };
  };
}
