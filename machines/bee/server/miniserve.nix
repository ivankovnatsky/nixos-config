{
  config,
  pkgs,
  ...
}:

let
  # Create auth file with username:password
  authFile = pkgs.writeText "miniserve-auth" "${config.secrets.miniserve.bee.username}:${config.secrets.miniserve.bee.password}";
in
{
  systemd.services.miniserve = {
    description = "Miniserve file server for /storage/Data";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "local-fs.target"
    ];

    # Service configuration
    serviceConfig = {
      ExecStart = ''
        ${pkgs.miniserve}/bin/miniserve \
          --interfaces 127.0.0.1 \
          --interfaces ::1 \
          --interfaces ${config.flags.beeIp} \
          --auth-file ${authFile} \
          /storage/Data
      '';
      Restart = "on-failure";
      RestartSec = "5s";

      # Security hardening
      DynamicUser = true;
      ProtectSystem = "full";
      ProtectHome = true;
      PrivateTmp = true;

      # Make sure the service can access the /storage/Data path
      ReadWritePaths = "/storage/Data";
    };
  };

  # Open port 8080 in firewall for miniserve
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
