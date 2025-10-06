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

      DynamicUser = true;
      StateDirectory = "beszel-hub";
      WorkingDirectory = "/var/lib/beszel-hub";

      ExecStart = "${pkgs.beszel}/bin/beszel-hub serve --http '${config.flags.beeIp}:8091'";

      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;

      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
    };
  };

  local.services.beszel-agent = {
    enable = true;
    port = 45876;
    hubPublicKey = config.secrets.beszel.hubPublicKey;
    openFirewall = true;
  };

  networking.firewall.allowedTCPPorts = [
    8091 # Beszel Hub web interface
  ];
}
