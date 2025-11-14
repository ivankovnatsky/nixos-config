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

    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      example = "192.168.1.10";
      description = "IP address to bind the Beszel Agent to. Defaults to all interfaces (0.0.0.0).";
    };

    hubPublicKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "SSH public key from the beszel hub";
    };

    hubPublicKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/var/run/secrets.d/1/beszel-hub-public-key";
      description = "Path to file containing SSH public key from the beszel hub";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.hubPublicKey != null) != (cfg.hubPublicKeyFile != null);
        message = "Exactly one of hubPublicKey or hubPublicKeyFile must be set for beszel-agent";
      }
    ];

    environment.systemPackages = [ cfg.package ];

    local.launchd.services.beszel-agent = {
      enable = true;
      type = "daemon";

      command = "${cfg.package}/bin/beszel-agent";

      environment = {
        LISTEN = "${cfg.listenAddress}:${toString cfg.port}";
        PATH = "${pkgs.coreutils}/bin:${cfg.package}/bin:${pkgs.bash}/bin";
      } // (
        if cfg.hubPublicKeyFile != null then {
          KEY_FILE = cfg.hubPublicKeyFile;
        } else {
          KEY = cfg.hubPublicKey;
        }
      );

      extraServiceConfig = {
        KeepAlive = {
          SuccessfulExit = false;
        };
      };
    };
  };
}
