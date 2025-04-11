{
  pkgs,
  ...
}:

{
  # Configure launchd service for miniserve file server
  launchd.user.agents.miniserve = {
    serviceConfig = {
      Label = "com.ivankovnatsky.miniserve";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/miniserve.log";
      StandardErrorPath = "/tmp/miniserve.error.log";
      # This makes the service attempt to start up again if it crashes
      ThrottleInterval = 10;
    };

    # Using command instead of ProgramArguments to utilize wait4path
    command =
      let
        # Create the miniserve starter script
        miniserveScript = pkgs.writeShellScriptBin "miniserve-starter" ''
          #!/bin/sh

          # Wait for the Samsung2TB volume to be mounted using the built-in wait4path utility
          echo "Waiting for /Volumes/Samsung2TB to be available..."
          /bin/wait4path "/Volumes/Samsung2TB"

          echo "/Volumes/Samsung2TB is now available!"
          echo "Starting miniserve..."

          # Launch miniserve with minimal options
          # --hidden: show hidden files
          exec ${pkgs.miniserve}/bin/miniserve --interfaces 0.0.0.0 --interfaces ::1 --hidden "/Volumes/Samsung2TB"
        '';
      in
      "${miniserveScript}/bin/miniserve-starter";
  };
}
