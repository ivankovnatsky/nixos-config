{ config, pkgs, ... }:

{
  local.launchd.services.taskchampion-sync-server = {
    enable = true;
    waitForPath = config.flags.externalStoragePath;
    command = ''
      ${pkgs.taskchampion-sync-server}/bin/taskchampion-sync-server \
        --listen ${config.flags.machineBindAddress}:10222 \
        --data-dir ${config.flags.externalStoragePath}/.taskchampion-sync-server
    '';
  };
}
