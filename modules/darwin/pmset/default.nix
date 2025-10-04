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

  config = {
    system.activationScripts.postActivation.text = mkAfter (
      if cfg.enable then
        let
          # Filter enabled schedules
          enabledSchedules = filterAttrs (name: schedule: schedule.enable) cfg.schedules;

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
        in
        generateAllSchedules enabledSchedules
      else
        ''
          echo "Disabling power management schedules"
          # Cancel any existing schedules
          /usr/bin/pmset repeat cancel

          # Verify schedules are cleared
          echo "Verifying schedules are cleared:"
          /usr/bin/pmset -g sched
        ''
    );
  };
}
