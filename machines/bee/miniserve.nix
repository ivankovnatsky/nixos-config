{
  pkgs,
  ...
}:

{
  systemd.services.miniserve = {
    description = "Miniserve file server for /storage";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "local-fs.target"
    ];

    # Service configuration
    serviceConfig = {
      ExecStart = "${pkgs.miniserve}/bin/miniserve --interfaces 0.0.0.0 --interfaces ::1 --hidden /storage";
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

  # Open port 8080 in firewall for miniserve
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
