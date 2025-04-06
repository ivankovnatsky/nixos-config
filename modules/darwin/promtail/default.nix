# Promtail service for Darwin systems
#
# This module configures promtail to run as a launchd service to collect and forward
# logs to a Loki instance.
#
# To check the logs of the promtail service:
# - View stdout logs: `cat /tmp/promtail.log`
# - View error logs: `cat /tmp/promtail.error.log`
# - Check service status: `launchctl list | grep promtail`
# - Stop service: `launchctl stop org.grafana.promtail`
# - Start service: `launchctl start org.grafana.promtail`
# - Reload config: `launchctl stop org.grafana.promtail && launchctl start org.grafana.promtail`
#
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.promtail;
  # Format the config as YAML to be written to a file
  configFile = pkgs.writeText "promtail-config.yaml" (builtins.toJSON cfg.configuration);
  # Binary package for promtail
  promtailBinary = "${pkgs.grafana-loki}/bin/promtail";
in
{
  options.services.promtail = {
    enable = mkEnableOption "Promtail log collector for Loki";

    configuration = mkOption {
      type = types.attrs;
      default = { };
      description = "Promtail configuration as a Nix attribute set. This will be converted to JSON.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.grafana-loki;
      description = "Package that provides promtail binary.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/promtail";
      description = "Directory to store promtail data.";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Environment file to pass to the promtail service.";
    };
  };

  config = mkIf cfg.enable {
    # Add documentation to make it easy to check status
    system.build.help = ''
      Promtail Service:
      - View logs: cat /tmp/promtail.log
      - View errors: cat /tmp/promtail.error.log
      - Check status: launchctl list | grep promtail
    '';
    environment.systemPackages = [ cfg.package ];

    launchd.daemons.promtail = {
      script = ''
        #!/bin/bash
        mkdir -p ${cfg.dataDir}
        ${promtailBinary} -config.file=${configFile} -config.expand-env=true
      '';
      serviceConfig = {
        Label = "org.grafana.promtail";
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/promtail.log";
        StandardErrorPath = "/tmp/promtail.error.log";
        EnvironmentVariables = {
          PATH = "${pkgs.coreutils}/bin:${cfg.package}/bin:${pkgs.bash}/bin";
        };
      };
    };

    # Create system directories
    system.activationScripts.preActivation.text = ''
      echo "Creating promtail directories..."
      mkdir -p ${cfg.dataDir}
      chmod 755 ${cfg.dataDir}
    '';
  };
}
