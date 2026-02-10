{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.syncthing-clean;
  pathArgs = builtins.concatStringsSep " " (map (p: ''"${p}"'') cfg.paths);
in
{
  options.local.services.syncthing-clean = {
    enable = mkEnableOption "Syncthing conflict file cleaner";

    paths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "/Users/ivan/Sources/github.com/ivankovnatsky/nixos-config"
        "/Users/ivan/Sources/github.com/ivankovnatsky/notes"
      ];
      description = "List of git repository paths to clean syncthing conflict files from";
    };

    intervalMinutes = mkOption {
      type = types.int;
      default = 15;
      description = "Interval in minutes between cleanup runs";
    };

    waitForPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/Volumes/Storage";
      description = "Path to wait for before running (useful for external volumes)";
    };

    delete = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to delete conflict files (false for dry-run)";
    };
  };

  config = mkIf cfg.enable {
    local.launchd.services.syncthing-clean = {
      enable = true;
      type = "user-agent";
      command =
        "${pkgs.syncthing-cleaner}/bin/syncthing-cleaner"
        + (optionalString cfg.delete " --delete")
        + " "
        + pathArgs;
      runAtLoad = false;
      keepAlive = false;
      inherit (cfg) waitForPath;
      environment = {
        PATH = "/run/current-system/sw/bin:${pkgs.fd}/bin:/usr/bin:/bin";
      };
      extraServiceConfig = {
        StartCalendarInterval =
          let
            minutes = genList (i: { Minute = i * cfg.intervalMinutes; }) (60 / cfg.intervalMinutes);
          in
          minutes;
      };
    };
  };
}
