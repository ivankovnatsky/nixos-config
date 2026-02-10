{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.syncthing-cleaner;
  pathArgs = builtins.concatStringsSep " " (map (p: ''"${p}"'') cfg.paths);
in
{
  options.local.services.syncthing-cleaner = {
    enable = mkEnableOption "Syncthing conflict file cleaner";

    paths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "/home/user/Sources/github.com/ivankovnatsky/nixos-config"
        "/home/user/Sources/github.com/ivankovnatsky/notes"
      ];
      description = "List of git repository paths to clean syncthing conflict files from";
    };

    intervalMinutes = mkOption {
      type = types.int;
      default = 15;
      description = "Interval in minutes between cleanup runs";
    };

    user = mkOption {
      type = types.str;
      description = "User to run the cleanup as";
    };

    delete = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to delete conflict files (false for dry-run)";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.syncthing-cleaner = {
      description = "Syncthing conflict file cleaner";
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        ExecStart =
          "${pkgs.syncthing-cleaner}/bin/syncthing-cleaner"
          + (optionalString cfg.delete " --delete")
          + " "
          + pathArgs;
        Environment = [
          "PATH=${pkgs.fd}/bin:${pkgs.coreutils}/bin:/run/current-system/sw/bin"
        ];
      };
    };

    systemd.timers.syncthing-cleaner = {
      description = "Timer for syncthing conflict file cleaner";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/${toString cfg.intervalMinutes}";
        Persistent = true;
      };
    };
  };
}
