{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.rebuildTerminal;

  terminalCommand = {
    "Terminal" = ''
      /usr/bin/osascript -e 'tell app "Terminal" to do script "/etc/profiles/per-user/$USER/bin/watchman-rebuild ${cfg.configPath}"'
    '';
    "kitty" = ''
      open -a kitty.app --args --hold /etc/profiles/per-user/$USER/bin/watchman-rebuild ${cfg.configPath}
    '';
    "ghostty" = ''
      open -a Ghostty.app --args -e /etc/profiles/per-user/$USER/bin/watchman-rebuild ${cfg.configPath}
    '';
  };
in
{
  options = {
    local.services.rebuildTerminal = {
      enable = mkEnableOption "automated rebuild via terminal (inherits Full Disk Access)";

      terminal = mkOption {
        type = types.enum [ "Terminal" "kitty" "ghostty" ];
        default = "Terminal";
        description = "Terminal emulator to use for rebuild commands";
      };

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
      command = terminalCommand.${cfg.terminal};
      runAtLoad = true;
      keepAlive = false;
    };
  };
}
