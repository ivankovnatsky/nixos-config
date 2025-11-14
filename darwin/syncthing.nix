{
  config,
  pkgs,
  ...
}:

# Syncthing configuration for Darwin systems
#
# Syncthing will be available at http://localnetworkIp:8384 after reboot or running:
# launchctl kickstart -k gui/$(id -u)/com.ivankovnatsky.syncthing
#
# Configuration will be stored in ~/Library/Application Support/Syncthing
# Log file will be at ~/Library/Logs/syncthing.log
#
# Note: This module only sets up the launchd service. You'll need to manually
# configure Syncthing devices and folders using the web interface.
#
# Assign only user permissions to dirs:
# ```console
# chmod 0700 $DIR1
# chmod 0700 $DIR2
# ```

let
  workingDirectory = config.flags.miniStoragePath; # External volume to wait for
  guiAddress = "${config.flags.miniIp}:8384";
in
{

  # Configure launchd service for Syncthing
  local.launchd.services.syncthing = {
    enable = true;
    type = "user-agent";
    keepAlive = true;
    throttleInterval = 10; # Restart on failure after 10 seconds
    waitForPath = workingDirectory;

    command = ''
      ${pkgs.syncthing}/bin/syncthing \
        -no-browser \
        -no-restart \
        -no-upgrade \
        -gui-address=${guiAddress} \
        -logflags=0
    '';
  };
}
