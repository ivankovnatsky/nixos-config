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

    # Get overdue tasks
    overdue=$(task rc.verbose=nothing +OVERDUE count 2>/dev/null || echo "0")
    if [ "$overdue" -gt 0 ]; then
      osascript -e "display notification \"$overdue task(s) overdue\" with title \"Taskwarrior\" sound name \"Basso\""
    fi

    # Get tasks due today that aren't overdue yet
    due_today=$(task rc.verbose=nothing +TODAY -OVERDUE count 2>/dev/null || echo "0")
    if [ "$due_today" -gt 0 ]; then
      osascript -e "display notification \"$due_today task(s) due today\" with title \"Taskwarrior\""
    fi
  '';
in
{
  options.local.taskwarrior-notify = {
    enable = mkEnableOption "taskwarrior due date notifications";

    interval = mkOption {
      type = types.int;
      default = 300;
      description = "Interval in seconds between checks (default: 5 minutes)";
    };
  };

  config = mkIf cfg.enable {
    local.launchd.services.taskwarrior-notify = {
      enable = true;
      type = "user-agent";
      keepAlive = false;
      runAtLoad = true;
      command = "${notifyScript}/bin/taskwarrior-notify";
      extraServiceConfig = {
        StartInterval = cfg.interval;
      };
    };
  };
}
