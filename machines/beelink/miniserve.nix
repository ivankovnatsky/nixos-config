{
  pkgs,
  ...
}:

{
  # Configure systemd service for miniserve file server
  systemd.services.miniserve = {
    description = "Miniserve file server for /storage";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "local-fs.target"
    ];

    # Service configuration
    serviceConfig = {
      ExecStart = "${pkgs.miniserve}/bin/miniserve --hidden /storage";
      Restart = "on-failure";
      RestartSec = "5s";

      # Security hardening
      DynamicUser = true;
      ProtectSystem = "full";
      ProtectHome = true;
      PrivateTmp = true;

      # Make sure the service can access the /storage path
      ReadWritePaths = "/storage";
    };
  };
}
