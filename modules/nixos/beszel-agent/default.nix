{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.local.services.beszel-agent;
in
{
  options.local.services.beszel-agent = {
    enable = lib.mkEnableOption "Beszel Agent - System monitoring agent";

    port = lib.mkOption {
      type = lib.types.port;
      default = 45876;
      description = "Port for the Beszel Agent to listen on";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      example = "192.168.1.10";
      description = "IP address to bind the Beszel Agent to. Defaults to all interfaces (0.0.0.0).";
    };

    hubPublicKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "ssh-ed25519 AAAAC3...";
      description = "Public key from the Beszel Hub for agent authentication (use hubPublicKeyFile for sops)";
    };

    hubPublicKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/secrets/beszel-hub-key";
      description = "Path to file containing the Beszel Hub public key (for use with sops-nix)";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall port for Beszel Agent";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.hubPublicKey != null) != (cfg.hubPublicKeyFile != null);
        message = "Exactly one of hubPublicKey or hubPublicKeyFile must be set for beszel-agent";
      }
    ];

    users.users.beszel-agent = {
      isSystemUser = true;
      group = "beszel-agent";
      description = "Beszel Agent service user";
    };

    users.groups.beszel-agent = { };

    systemd.services.beszel-agent = {
      description = "Beszel Agent - System monitoring agent";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "docker.service"
      ];

      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "5s";

        User = "beszel-agent";
        Group = "beszel-agent";
        StateDirectory = "beszel-agent";
        SupplementaryGroups = [ "docker" ];

        Environment =
          [ "LISTEN=${cfg.listenAddress}:${toString cfg.port}" ]
          ++ (
            if cfg.hubPublicKeyFile != null then
              [ "KEY_FILE=${cfg.hubPublicKeyFile}" ]
            else
              [ "KEY=${cfg.hubPublicKey}" ]
          );

        ExecStart = "${pkgs.beszel}/bin/beszel-agent";

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

        PrivateTmp = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
