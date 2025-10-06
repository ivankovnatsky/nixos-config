{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.beszel-agent;
in
{
  options.local.services.beszel-agent = {
    enable = mkEnableOption "Beszel Agent - System monitoring agent";

    package = mkOption {
      type = types.package;
      default = pkgs.beszel;
      defaultText = literalExpression "pkgs.beszel";
      description = "The beszel package to use.";
    };

    port = mkOption {
      type = types.port;
      default = 45876;
      description = "Port for the beszel agent to listen on";
    };

    hubPublicKey = mkOption {
      type = types.str;
      description = "SSH public key from the beszel hub";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    launchd.daemons.beszel-agent = {
      script = ''
        #!/bin/bash
        mkdir -p /tmp/log/launchd
        exec ${cfg.package}/bin/beszel-agent
      '';

      serviceConfig = {
        Label = "dev.beszel.agent";
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
        };
        StandardOutPath = "/tmp/log/launchd/beszel-agent.log";
        StandardErrorPath = "/tmp/log/launchd/beszel-agent.error.log";
        EnvironmentVariables = {
          LISTEN = toString cfg.port;
          KEY = cfg.hubPublicKey;
          PATH = "${pkgs.coreutils}/bin:${cfg.package}/bin:${pkgs.bash}/bin";
        };
      };
    };
  };
}
