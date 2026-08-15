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
            Blocks until the path exists.
            Useful for services that depend on external volumes being mounted.
          '';
        };

        waitForSecrets = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Wait for sops-nix secrets to be available before starting the service.
            Blocks until ~/.config/sops-nix/secrets exists.
            Enable this for services that depend on sops secrets.
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
        set -e

        # Add basic Darwin utilities to PATH for preStart scripts
        export PATH="/bin:/usr/bin:$PATH"

        # Create log directory with proper permissions
        /bin/mkdir -p ${svc.logDir}
        /bin/chmod 755 ${svc.logDir}

        ${optionalString svc.waitForSecrets ''
          echo "Waiting for sops secrets..."
          while [ ! -e ${config.home.homeDirectory}/.config/sops-nix/secrets ]; do
            sleep 1
          done
          echo "Sops secrets available."
        ''}

        ${optionalString (svc.waitForPath != null) ''
          echo "Waiting for ${svc.waitForPath}..."
          while [ ! -e "${svc.waitForPath}" ]; do
            sleep 1
          done
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
    in
    {
      enable = true;
      config = {
        Label = svc.label;
        # Inline the starter via `bash -c` instead of writing a script file to
        # /nix/store. launchd-spawned processes on macOS cannot open() script
        # files on external Nix stores (EPERM), but Mach-O exec of bash itself
        # works — so we pass the script body via -c to skip the file open.
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          scriptContent
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
