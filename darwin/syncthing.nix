{
  config,
  lib,
  pkgs,
  ...
}:

# https://docs.syncthing.net/v1.29.0/users/config#config-option-folder.maxconflicts
#
# Syncthing configuration for Darwin systems
#
# For servers (mini): binds to network IP, waits for external storage
# For laptops (air/pro): binds to localhost only
#
# Syncthing will be available at the configured address after reboot or running:
# launchctl kickstart -k gui/$(id -u)/com.ivankovnatsky.syncthing
#
# Configuration will be stored in ~/Library/Application Support/Syncthing
# Log file will be at /tmp/agents/log/launchd/syncthing.log

let
  isServer = config.device.type == "server";
  guiAddress =
    if isServer then "${config.flags.miniIp}:8384" else "127.0.0.1:8384";
in
{
  local.launchd.services.syncthing = {
    enable = true;
    type = "user-agent";
    keepAlive = true;
    throttleInterval = 10;
    waitForPath = lib.mkIf isServer config.flags.miniStoragePath;

    command = ''
      ${pkgs.syncthing}/bin/syncthing serve \
        --no-browser \
        --no-restart \
        --no-upgrade \
        --gui-address=${guiAddress}
    '';
  };
}
