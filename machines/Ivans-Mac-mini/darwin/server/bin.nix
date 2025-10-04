{
  config,
  pkgs,
  ...
}:

{
  # Configure launchd service for bin paste bin server
  launchd.user.agents.bin = {
    serviceConfig = {
      Label = "com.ivankovnatsky.bin";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/bin.log";
      StandardErrorPath = "/tmp/agents/log/launchd/bin.error.log";
      # This makes the service attempt to start up again if it crashes
      ThrottleInterval = 10;
    };

    # Using command to run bin paste bin server
    command =
      let
        # Create the bin starter script
        binScript = pkgs.writeShellScriptBin "bin-starter" ''
          echo "Starting bin paste bin server..."

          # Launch bin with custom settings
          exec ${pkgs.bin}/bin/bin \
            ${config.flags.miniIp}:8820 \
            --buffer-size 2000 \
            --max-paste-size 65536
        '';
      in
      "${binScript}/bin/bin-starter";
  };
}
