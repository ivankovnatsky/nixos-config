{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  inherit (lib) filterAttrs;
  cfg = config.local.services.pmset;
in
{
  options.local.services.pmset = {
    enable = mkEnableOption "pmset power management scheduling";

    powerMode = {
      battery = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable low power mode when on battery (true = enabled, false = disabled, null = no change)";
      };

      ac = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable low power mode when on AC power (true = enabled, false = disabled, null = no change)";
      };
    };

    schedules = mkOption {
      default = { };
      description = "Power management schedules";
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkEnableOption "this schedule";

            time = mkOption {
              type = types.str;
              example = "22:30:00";
              description = "Time to schedule the action every day (format: HH:MM:SS)";
            };

            action = mkOption {
              type = types.enum [
                "sleep"
                "shutdown"
                "restart"
                "wakeorpoweron"
              ];
              description = "Power action to perform at the scheduled time";
            };

            days = mkOption {
              type = types.str;
              default = "MTWRFSU";
              description = "Days to apply schedule (M=Monday, T=Tuesday, W=Wednesday, R=Thursday, F=Friday, S=Saturday, U=Sunday)";
            };
          };
        }
      );
    };
  };

  config = mkIf cfg.enable {
    local.launchd.services.pmset-mgmt = {
      enable = true;
      type = "daemon"; # Requires root for pmset commands
      label = "org.nixos.pmset-mgmt";
      runAtLoad = true; # Run when daemon is loaded/reloaded on rebuild
      keepAlive = false; # One-shot job - exit after completion

      command = let
        # Filter enabled schedules
        enabledSchedules = filterAttrs (name: schedule: schedule.enable) cfg.schedules;

        # Generate power mode settings
        powerModeSettings = ''
          ${optionalString (cfg.powerMode.battery != null) ''
            echo "Setting low power mode for battery: ${if cfg.powerMode.battery then "enabled" else "disabled"}"
            /usr/bin/pmset -b lowpowermode ${if cfg.powerMode.battery then "1" else "0"}
          ''}
          ${optionalString (cfg.powerMode.ac != null) ''
            echo "Setting low power mode for AC: ${if cfg.powerMode.ac then "enabled" else "disabled"}"
            /usr/bin/pmset -c lowpowermode ${if cfg.powerMode.ac then "1" else "0"}
          ''}
          ${optionalString (cfg.powerMode.battery != null || cfg.powerMode.ac != null) ''
            echo "Verifying power mode settings:"
            /usr/bin/pmset -g custom
          ''}
        '';

        # Generate a single pmset repeat command with all schedules
        generateAllSchedules =
          schedules:
          let
            # Format each schedule as "action days time"
            formatSchedule = name: schedule: "${schedule.action} ${schedule.days} ${schedule.time}";

            # Join all schedule parameters
            scheduleParams = concatStringsSep " " (mapAttrsToList formatSchedule schedules);
          in
          optionalString (scheduleParams != "") ''
            echo "Setting power management schedules"
            # Cancel any existing schedules first
            /usr/bin/pmset repeat cancel

            # Set all schedules in a single command
            /usr/bin/pmset repeat ${scheduleParams}

            # Verify the schedules
            echo "Verifying schedules:"
            /usr/bin/pmset -g sched
          '';

        pmsetScript = pkgs.writeShellScript "pmset-mgmt" ''
          set -e
          echo "Starting pmset management..."

          ${powerModeSettings}
          ${generateAllSchedules enabledSchedules}

          echo "pmset management completed"
        '';
      in "${pmsetScript}";
    };
  };
}
