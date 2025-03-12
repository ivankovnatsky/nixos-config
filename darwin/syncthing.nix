{
  config,
  pkgs,
  lib,
  ...
}:

# Syncthing configuration for Darwin systems
#
# Syncthing will be available at http://0.0.0.0:8384 after reboot or running:
# launchctl kickstart -k gui/$(id -u)/net.syncthing.syncthing
#
# Configuration will be stored in ~/Library/Application Support/Syncthing
# Log file will be at ~/Library/Logs/syncthing.log
#
# Note: This module only sets up the launchd service. You'll need to manually
# configure Syncthing devices and folders using the web interface.

let
  username = "ivan"; # Set your username here
  homeDir = "/Users/${username}";
  configDir = "${homeDir}/Library/Application Support/Syncthing";
  guiAddress = "0.0.0.0:8384"; # Accept connections from any interface
in
{

  # Configure launchd service for Syncthing
  launchd.user.agents.syncthing = {
    serviceConfig = {
      Label = "net.syncthing.syncthing";
      ProgramArguments = [
        "${pkgs.syncthing}/bin/syncthing"
        "-no-browser"
        "-no-restart"
        "-logflags=0"
      ];
      EnvironmentVariables = {
        # Set environment variables
        STNOUPGRADE = "1"; # Disable automatic upgrades as it's managed by Nix
        # GUI address is controlled by the user via the web interface
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${homeDir}/Library/Logs/syncthing.log";
      StandardErrorPath = "${homeDir}/Library/Logs/syncthing.log";
      WorkingDirectory = homeDir;
    };
  };
}
