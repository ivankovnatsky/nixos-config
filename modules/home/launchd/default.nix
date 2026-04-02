{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.launchd;

  serviceType = types.submodule (
    { name, config, ... }:
    {
      options = {
        enable = mkEnableOption "this launchd service";

        label = mkOption {
          type = types.str;
          default = "com.ivankovnatsky.${name}";
          description = "LaunchD label for the service";
        };

        command = mkOption {
          type = types.str;
          description = "Command to execute";
        };

        waitForPath = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "/Volumes/ExternalDrive";
          description = ''
            Optional path to wait for before starting the service.
            Uses /bin/wait4path to block until the path exists.
            Useful for services that depend on external volumes being mounted.
          '';
        };

        waitForSecrets = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Wait for sops-nix secrets to be available before starting the service.
            Uses /bin/wait4path to block until /run/secrets exists.
            Enable this for services that depend on sops secrets or templates.
          '';
        };

        dataDir = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "/Volumes/ExternalDrive/Data/.myservice";
          description = "Primary data directory to create";
        };

        extraDirs = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [
            "/Volumes/ExternalDrive/Data/Media/TV"
            "/Volumes/ExternalDrive/Data/Media/Downloads"
          ];
          description = "Additional directories to create on startup";
        };

        preStart = mkOption {
          type = types.lines;
          default = "";
          description = "Shell commands to run before starting the service";
        };

        environment = mkOption {
          type = types.attrsOf types.str;
          default = { };
          example = {
            PATH = "/usr/bin:/bin";
          };
          description = "Environment variables";
        };

        runAtLoad = mkOption {
          type = types.bool;
          default = true;
          description = "Start service automatically at load";
        };

        keepAlive = mkOption {
          type = types.bool;
          default = true;
          description = "Restart service if it exits";
        };

        throttleInterval = mkOption {
          type = types.int;
          default = 10;
          description = "Seconds to wait before restarting after crash";
        };

        logTimestamp = mkOption {
          type = types.bool;
          default = true;
          description = "Prefix command output lines with timestamps and log level";
        };

        logDir = mkOption {
          type = types.str;
          default = "/tmp/agents/log/launchd";
          description = "Directory for log files";
        };

        extraServiceConfig = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = "Additional serviceConfig attributes";
        };
      };
    }
  );

  mkService =
    name: svc:
    let
      logPath = "${svc.logDir}/${name}.log";
      errorLogPath = "${svc.logDir}/${name}.error.log";

      scriptContent = ''
        #!/bin/bash
        set -e

        # Add basic Darwin utilities to PATH for preStart scripts
        export PATH="/bin:/usr/bin:$PATH"

        ts() { date '+%Y-%m-%d %H:%M:%S'; }

        # Create log directory with proper permissions
        /bin/mkdir -p ${svc.logDir}
        /bin/chmod 755 ${svc.logDir}

        ${optionalString svc.waitForSecrets ''
          echo "$(ts) - INFO - Waiting for sops secrets to be available..."
          /bin/wait4path /run/secrets
          echo "$(ts) - INFO - Sops secrets are available!"
        ''}

        ${optionalString (svc.waitForPath != null) ''
          echo "$(ts) - INFO - Waiting for ${svc.waitForPath}..."
          /bin/wait4path "${svc.waitForPath}"
          echo "$(ts) - INFO - ${svc.waitForPath} is available!"
        ''}

        ${optionalString (svc.dataDir != null) ''
          /bin/mkdir -p "${svc.dataDir}"
        ''}

        ${optionalString (svc.extraDirs != [ ]) ''
          ${concatMapStringsSep "\n" (dir: "/bin/mkdir -p \"${dir}\"") svc.extraDirs}
        ''}

        ${svc.preStart}

        ${
          if svc.logTimestamp then
            ''
              ${svc.command} \
                > >(while IFS= read -r line; do printf '%s - INFO - %s\n' "$(ts)" "$line"; done) \
                2> >(while IFS= read -r line; do printf '%s - ERROR - %s\n' "$(ts)" "$line"; done >&2)
            ''
          else
            ''
              exec ${svc.command}
            ''
        }
      '';

      script = pkgs.writeShellScriptBin "${name}-starter" scriptContent;
    in
    {
      enable = true;
      config =
        {
          Label = svc.label;
          ProgramArguments = [
            "${script}/bin/${name}-starter"
          ];
          RunAtLoad = svc.runAtLoad;
          KeepAlive = svc.keepAlive;
          ThrottleInterval = svc.throttleInterval;
          StandardOutPath = logPath;
          StandardErrorPath = errorLogPath;
        }
        // optionalAttrs (svc.environment != { }) { EnvironmentVariables = svc.environment; }
        // svc.extraServiceConfig;
    };

  enabledServices = filterAttrs (_: s: s.enable) cfg.services;
in
{
  options.local.launchd = {
    services = mkOption {
      type = types.attrsOf serviceType;
      default = { };
      description = "Declarative launchd user agent definitions for home-manager";
    };
  };

  config = mkIf (enabledServices != { }) {
    launchd.agents = mapAttrs mkService enabledServices;
  };
}
