{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.taskwarrior-notify;

  notifyScript = pkgs.writeShellScriptBin "taskwarrior-notify" ''
    # Check for due and overdue tasks and send macOS notifications
    export PATH="${pkgs.taskwarrior3}/bin:$PATH"

    # Get overdue tasks with details
    overdue=$(task rc.verbose=nothing +OVERDUE count 2>/dev/null || echo "0")
    if [ "$overdue" -gt 0 ]; then
      details=$(task rc.verbose=nothing rc.report.next.columns=description.truncated rc.report.next.labels=Task +OVERDUE limit:3 next 2>/dev/null | sed 's/"/\\"/g')
      osascript -e "display notification \"$details\" with title \"Taskwarrior: $overdue overdue\" sound name \"Basso\""
    fi

    # Get tasks due today that aren't overdue yet
    due_today=$(task rc.verbose=nothing +TODAY -OVERDUE count 2>/dev/null || echo "0")
    if [ "$due_today" -gt 0 ]; then
      details=$(task rc.verbose=nothing rc.report.next.columns=description.truncated rc.report.next.labels=Task +TODAY -OVERDUE limit:3 next 2>/dev/null | sed 's/"/\\"/g')
      osascript -e "display notification \"$details\" with title \"Taskwarrior: $due_today due today\""
    fi
  '';
in
{
  options.local.taskwarrior-notify = {
    enable = mkEnableOption "taskwarrior due date notifications";

    interval = mkOption {
      type = types.int;
      default = 3600;
      description = "Interval in seconds between checks (default: 1 hour)";
    };
  };

  config = mkIf cfg.enable {
    local.launchd.services.taskwarrior-notify = {
      enable = true;
      keepAlive = false;
      runAtLoad = true;
      command = "${notifyScript}/bin/taskwarrior-notify";
      extraServiceConfig = {
        StartInterval = cfg.interval;
      };
    };
  };
}
