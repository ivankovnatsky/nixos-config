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
    export PATH="${pkgs.taskwarrior3}/bin:$PATH"

    task rc.verbose=nothing +OVERDUE export 2>/dev/null | ${pkgs.jq}/bin/jq -r 'sort_by(-.urgency) | .[].description' | while IFS= read -r desc; do
      escaped=$(printf '%s' "$desc" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
      osascript -e "display notification \"$escaped\" with title \"Taskwarrior: overdue\" sound name \"Basso\""
    done
  '';
in
{
  options.local.taskwarrior-notify = {
    enable = mkEnableOption "taskwarrior due date notifications";
  };

  config = mkIf cfg.enable {
    local.launchd.services.taskwarrior-notify = {
      enable = true;
      keepAlive = false;
      runAtLoad = false;
      command = "${notifyScript}/bin/taskwarrior-notify";
      extraServiceConfig = {
        StartCalendarInterval = {
          Hour = 12;
          Minute = 0;
        };
      };
    };
  };
}
