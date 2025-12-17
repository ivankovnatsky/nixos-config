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

        type = mkOption {
          type = types.enum [
            "user-agent"
            "daemon"
          ];
          default = "user-agent";
          description = "Whether to run as user agent or system daemon";
        };

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
            Uses /bin/wait4path to block until /run/secrets/rendered exists.
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
          default = if config.type == "daemon" then "/tmp/log/launchd" else "/tmp/agents/log/launchd";
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

  mkService =
    name: cfg:
    let
      logPath = "${cfg.logDir}/${name}.log";
      errorLogPath = "${cfg.logDir}/${name}.error.log";

      scriptContent = ''
        #!/bin/bash
        set -e

        # Add basic Darwin utilities to PATH for preStart scripts
        export PATH="/bin:/usr/bin:$PATH"

        # Create log directory with proper permissions
        /bin/mkdir -p ${cfg.logDir}
        /bin/chmod 755 ${cfg.logDir}

        ${optionalString cfg.waitForSecrets ''
          echo "Waiting for sops secrets to be available..."
          /bin/wait4path /run/secrets/rendered
          echo "Sops secrets are available!"
        ''}

        ${optionalString (cfg.waitForPath != null) ''
          echo "Waiting for ${cfg.waitForPath}..."
          /bin/wait4path "${cfg.waitForPath}"
          echo "${cfg.waitForPath} is available!"
        ''}

        ${optionalString (cfg.dataDir != null) ''
          /bin/mkdir -p "${cfg.dataDir}"
        ''}

        ${optionalString (cfg.extraDirs != [ ]) ''
          ${concatMapStringsSep "\n" (dir: "/bin/mkdir -p \"${dir}\"") cfg.extraDirs}
        ''}

        ${cfg.preStart}

        echo "Starting ${name}..."
        exec ${cfg.command}
      '';

      script = pkgs.writeShellScriptBin "${name}-starter" scriptContent;

      serviceConfig =
        {
          Label = cfg.label;
          RunAtLoad = cfg.runAtLoad;
          KeepAlive = cfg.keepAlive;
          ThrottleInterval = cfg.throttleInterval;
          StandardOutPath = logPath;
          StandardErrorPath = errorLogPath;
        }
        // optionalAttrs (cfg.environment != { }) { EnvironmentVariables = cfg.environment; }
        // cfg.extraServiceConfig;
    in
    {
      command = "${script}/bin/${name}-starter";
      inherit serviceConfig;
    };
  # Generate activation script for log file ownership
  mkLogOwnershipScript =
    let
      servicesWithUser = filterAttrs (
        _: s: s.enable && s.extraServiceConfig ? UserName
      ) cfg.services;
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
in
{
  options.local.launchd = {
    services = mkOption {
      type = types.attrsOf serviceType;
      default = { };
      description = "Declarative launchd service definitions";
    };
  };

  config = mkMerge [
    # Generate user agents
    (mkIf (any (s: s.enable && s.type == "user-agent") (attrValues cfg.services)) {
      launchd.user.agents = mapAttrs' (
        name: service:
        nameValuePair name (mkService name service)
      ) (filterAttrs (_: s: s.enable && s.type == "user-agent") cfg.services);
    })

    # Generate daemons
    (mkIf (any (s: s.enable && s.type == "daemon") (attrValues cfg.services)) {
      launchd.daemons = mapAttrs' (
        name: service:
        nameValuePair name (mkService name service)
      ) (filterAttrs (_: s: s.enable && s.type == "daemon") cfg.services);
    })

    # Activation script to fix log file ownership for services with UserName
    (mkIf (any (s: s.enable && s.extraServiceConfig ? UserName) (attrValues cfg.services)) {
      system.activationScripts.postActivation.text = mkLogOwnershipScript;
    })
  ];
}
