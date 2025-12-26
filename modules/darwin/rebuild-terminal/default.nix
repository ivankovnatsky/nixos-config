{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.local.services.rebuildTerminal;
in
{
  options = {
    local.services.rebuildTerminal = {
      enable = mkEnableOption "automated rebuild via Terminal.app (inherits Full Disk Access)";

      configPath = mkOption {
        type = types.str;
        description = "Path to the nixos-config repository";
      };
    };
  };

  config = mkIf cfg.enable {
    local.launchd.services.rebuild-terminal = {
      enable = true;
      type = "user-agent";
      command = ''
        /usr/bin/osascript -e 'tell app "Terminal" to do script "/etc/profiles/per-user/$USER/bin/watchman-rebuild ${cfg.configPath}"'
      '';
      runAtLoad = true;
      keepAlive = false;
    };
  };
}
