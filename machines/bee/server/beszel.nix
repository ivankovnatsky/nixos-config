{ config, pkgs, ... }:
{
  systemd.services.beszel-hub = {
    description = "Beszel Hub - Lightweight server monitoring";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "3s";

      # Create a dedicated user for beszel
      DynamicUser = true;
      StateDirectory = "beszel-hub";
      WorkingDirectory = "/var/lib/beszel-hub";

      ExecStart = "${pkgs.beszel}/bin/beszel-hub serve --http '${config.flags.beeIp}:8091'";

      # Security hardening
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;

      # Restrict network access to only what's needed
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
    };
  };

  # Open firewall port for Beszel web interface
  networking.firewall.allowedTCPPorts = [ 8091 ];
}
