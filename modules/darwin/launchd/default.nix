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
        enable = mkEnableOption "this launchd daemon service";

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
          default = "/tmp/log/launchd";
          description = "Directory for log files";
        };

        extraServiceConfig = mkOption {
          type = types.attrs;
          default = { };
          description = "Additional serviceConfig attributes";
        };
      };
    }
  );

  enabledDaemons = filterAttrs (_: s: s.enable) cfg.services;

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

      serviceConfig = {
        Label = svc.label;
        RunAtLoad = svc.runAtLoad;
        KeepAlive = svc.keepAlive;
        ThrottleInterval = svc.throttleInterval;
        StandardOutPath = logPath;
        StandardErrorPath = errorLogPath;
      }
      // optionalAttrs (svc.environment != { }) { EnvironmentVariables = svc.environment; }
      // svc.extraServiceConfig;
    in
    {
      command = "${script}/bin/${name}-starter";
      inherit serviceConfig;
    };

  # Generate activation script for log file ownership
  mkLogOwnershipScript =
    let
      servicesWithUser = filterAttrs (_: s: s.enable && s.extraServiceConfig ? UserName) cfg.services;
    in
    concatStringsSep "\n" (
      mapAttrsToList (
        name: service:
        let
          userName = service.extraServiceConfig.UserName;
          groupName = service.extraServiceConfig.GroupName or "staff";
          logPath = "${service.logDir}/${name}.log";
          errorLogPath = "${service.logDir}/${name}.error.log";
        in
        ''
          # Ensure log files for ${name} are owned by ${userName}:${groupName}
          /bin/mkdir -p ${service.logDir}
          /usr/bin/touch ${logPath} ${errorLogPath}
          /usr/sbin/chown ${userName}:${groupName} ${logPath} ${errorLogPath}
        ''
      ) servicesWithUser
    );

  # Generate activation script to ensure daemons are loaded
  # This fixes the issue where nix-darwin skips loading if file unchanged
  mkEnsureDaemonsLoadedScript = concatStringsSep "\n" (
    mapAttrsToList (
      name: service:
      let
        inherit (service) label;
        plistPath = "/Library/LaunchDaemons/${label}.plist";
      in
      ''
        # Ensure ${name} daemon is loaded
        if ! /bin/launchctl list "${label}" &>/dev/null; then
          echo "Loading daemon ${label}..."
          /bin/launchctl load -w "${plistPath}" 2>/dev/null || true
        fi
      ''
    ) enabledDaemons
  );
in
{
  options.local.launchd = {
    services = mkOption {
      type = types.attrsOf serviceType;
      default = { };
      description = "Declarative launchd daemon service definitions";
    };
  };

  config = mkMerge [
    # Generate daemons
    (mkIf (enabledDaemons != { }) {
      launchd.daemons = mapAttrs' (
        name: service: nameValuePair name (mkService name service)
      ) enabledDaemons;
    })

    # Activation script to fix log file ownership for services with UserName
    (mkIf (any (s: s.enable && s.extraServiceConfig ? UserName) (attrValues cfg.services)) {
      system.activationScripts.postActivation.text = mkLogOwnershipScript;
    })

    # Activation script to ensure daemons are loaded
    # This fixes the issue where nix-darwin skips loading if file unchanged
    (mkIf (enabledDaemons != { }) {
      system.activationScripts.postActivation.text = mkAfter mkEnsureDaemonsLoadedScript;
    })
  ];
}
