{
  config,
  pkgs,
  ...
}:

# Syncthing configuration for Darwin systems
#
# Syncthing will be available at http://localnetworkIp:8384 after reboot or running:
# launchctl kickstart -k gui/$(id -u)/net.syncthing.syncthing
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
  launchd.user.agents.syncthing = {
    serviceConfig = {
      Label = "net.syncthing.syncthing";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/syncthing.log";
      StandardErrorPath = "/tmp/agents/log/launchd/syncthing.error.log";
      ThrottleInterval = 10; # Restart on failure after 10 seconds
    };

    # Using command instead of ProgramArguments to utilize wait4path
    command =
      let
        # Create a startup script that waits for external volume to be fully available
        startupScript = pkgs.writeShellScriptBin "syncthing-start" ''
          # Wait for the external volume to be available
          /bin/wait4path "${workingDirectory}"

          # Execute Syncthing with parameters
          exec ${pkgs.syncthing}/bin/syncthing \
            -no-browser \
            -no-restart \
            -no-upgrade \
            -gui-address=${guiAddress} \
            -logflags=0
        '';
      in
      "${startupScript}/bin/syncthing-start";
  };
}
