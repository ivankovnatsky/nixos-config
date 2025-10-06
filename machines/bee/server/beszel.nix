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

  systemd.services.beszel-agent = {
    description = "Beszel Agent - System monitoring agent";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "docker.service" ];

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "5s";

      # Create a dedicated user for beszel agent
      DynamicUser = true;
      StateDirectory = "beszel-agent";
      SupplementaryGroups = [ "docker" ];

      # Use environment variables for configuration
      Environment = [
        "LISTEN=45876"
      ];

      # KEY needs to be set separately to handle spaces in the value
      EnvironmentFile = pkgs.writeText "beszel-agent.env" ''
        KEY=${config.secrets.beszel.hubPublicKey}
      '';

      ExecStart = "${pkgs.beszel}/bin/beszel-agent";

      # Security/sandboxing settings (from official service unit)
      KeyringMode = "private";
      LockPersonality = true;
      NoNewPrivileges = true;
      ProtectClock = true;
      ProtectHome = "read-only";
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictSUIDSGID = true;

      # Additional restrictions
      PrivateTmp = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
    };
  };

  # Open firewall ports
  networking.firewall.allowedTCPPorts = [
    8091 # Beszel Hub web interface
    45876 # Beszel Agent
  ];
}
