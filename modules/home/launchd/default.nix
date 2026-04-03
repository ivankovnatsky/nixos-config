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
    { name, ... }:
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

        # Create log directory with proper permissions
        /bin/mkdir -p ${svc.logDir}
        /bin/chmod 755 ${svc.logDir}

        ${optionalString svc.waitForSecrets ''
          echo "Waiting for sops secrets..."
          /bin/wait4path /run/secrets
          echo "Sops secrets available."
        ''}

        ${optionalString (svc.waitForPath != null) ''
          echo "Waiting for ${svc.waitForPath}..."
          /bin/wait4path "${svc.waitForPath}"
          echo "${svc.waitForPath} available."
        ''}

        ${optionalString (svc.dataDir != null) ''
          /bin/mkdir -p "${svc.dataDir}"
        ''}

        ${optionalString (svc.extraDirs != [ ]) ''
          ${concatMapStringsSep "\n" (dir: "/bin/mkdir -p \"${dir}\"") svc.extraDirs}
        ''}

        ${svc.preStart}

        exec ${svc.command}
      '';

      script = pkgs.writeShellScriptBin "${name}-starter" scriptContent;
    in
    {
      enable = true;
      config = {
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

    # Pre-create log files so launchd can open StandardOutPath/StandardErrorPath
    # before the starter script runs (launchd opens these before exec).
    home.activation.launchdLogFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      concatStringsSep "\n" (
        mapAttrsToList (
          name: svc:
          let
            logPath = "${svc.logDir}/${name}.log";
            errorLogPath = "${svc.logDir}/${name}.error.log";
          in
          ''
            /bin/mkdir -p "${svc.logDir}"
            /usr/bin/touch "${logPath}" "${errorLogPath}"
          ''
        ) enabledServices
      )
    );
  };
}
