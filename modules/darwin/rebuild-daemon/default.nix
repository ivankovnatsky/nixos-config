{ pkgs
, config
, lib
, ...
}:

with lib;

let
  cfg = config.local.services.rebuildDaemon;
in
{
  options = {
    local.services.rebuildDaemon = {
      enable = mkEnableOption "automated rebuild daemon with watchman";

      configPath = mkOption {
        type = types.str;
        description = "Path to the nixos-config repository";
      };
    };
  };

  config = mkIf cfg.enable {
    local.launchd.services.rebuild-daemon = {
      enable = true;
      type = "daemon";
      waitForPath = cfg.configPath;
      environment = {
        PATH = "/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      command = ''
        ${pkgs.watchman-rebuild}/bin/watchman-rebuild ${cfg.configPath}
      '';
      keepAlive = true;
      throttleInterval = 10;
      extraServiceConfig = {
        Umask = 18; # 022 in octal = 18 in decimal, makes logs readable by all
      };
    };
  };
}
