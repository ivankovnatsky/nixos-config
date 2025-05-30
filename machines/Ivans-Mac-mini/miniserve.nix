{
  config,
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
      StandardOutPath = "/tmp/agents/log/launchd/miniserve.log";
      StandardErrorPath = "/tmp/agents/log/launchd/miniserve.error.log";
      # This makes the service attempt to start up again if it crashes
      ThrottleInterval = 10;
    };

    # Using command instead of ProgramArguments to utilize wait4path
    command =
      let
        # Create auth file with username:password
        authFile = pkgs.writeText "miniserve-auth" "${config.secrets.miniserve.mini.username}:${config.secrets.miniserve.mini.password}";

        # Create the miniserve starter script
        miniserveScript = pkgs.writeShellScriptBin "miniserve-starter" ''
          # Wait for the Storage volume to be mounted using the built-in wait4path utility
          echo "Waiting for /Volumes/Storage to be available..."
          /bin/wait4path "/Volumes/Storage"

          echo "/Volumes/Storage is now available!"
          echo "Starting miniserve..."

          # Launch miniserve with authentication
          exec ${pkgs.miniserve}/bin/miniserve \
            --interfaces 127.0.0.1 \
            --interfaces ::1 \
            --interfaces ${config.flags.miniIp} \
            --auth-file ${authFile} \
            "/Volumes/Storage/Data"
        '';
      in
      "${miniserveScript}/bin/miniserve-starter";
  };
}
