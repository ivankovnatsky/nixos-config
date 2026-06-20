{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.notifications;

  hhmmType = types.strMatching "([01]?[0-9]|2[0-3]):[0-5][0-9]";
  hourOf = at: toIntBase10 (elemAt (splitString ":" at) 0);
  minuteOf = at: toIntBase10 (elemAt (splitString ":" at) 1);
in
{
  options.local.services.notifications = {
    discordWebhookFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to a file containing a Discord webhook URL, shared by all
        notification features that target Discord.
      '';
    };

    battery = {
      enable = mkEnableOption "daily battery state notifications";

      at = mkOption {
        type = hhmmType;
        default = "21:00";
        example = "21:00";
        description = ''
          Local time (HH:MM) at which to send the daily battery
          notification. Backed by launchd StartCalendarInterval: if the
          Mac is asleep at the appointed time, the job runs on next
          wake (multiple missed fires coalesce into one).
        '';
      };
    };

    digest = {
      enable = mkEnableOption "daily flush of the shared notification digest";

      at = mkOption {
        type = hhmmType;
        default = "21:00";
        example = "21:00";
        description = ''
          Local time (HH:MM) at which to post all pending digest
          notifications. Producers (reposync, rebuild) record failures into
          a shared state file instead of alerting immediately; this job posts
          whatever is still pending and clears it. Anything a producer cleared
          before this time (e.g. a repo that re-synced, or a rebuild that
          later succeeded) is dropped silently and never reaches Discord.
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.battery.enable {
      assertions = [
        {
          assertion = cfg.discordWebhookFile != null;
          message = ''
            local.services.notifications.battery.enable requires
            local.services.notifications.discordWebhookFile to be set.
          '';
        }
      ];

      local.launchd.services.notifications-battery = {
        enable = true;
        keepAlive = false;
        runAtLoad = false;
        waitForSecrets = true;

        command =
          let
            script = pkgs.writeShellScript "notifications-battery-run" ''
              set -e
              exec ${pkgs.notifications}/bin/notifications battery \
                --webhook-file ${escapeShellArg cfg.discordWebhookFile}
            '';
          in
          "${script}";

        extraServiceConfig = {
          StartCalendarInterval = [
            {
              Hour = hourOf cfg.battery.at;
              Minute = minuteOf cfg.battery.at;
            }
          ];
        };
      };
    })

    (mkIf (cfg.digest.enable && pkgs.stdenv.isDarwin) {
      local.launchd.services.notifications-digest = {
        enable = true;
        keepAlive = false;
        runAtLoad = false;
        waitForSecrets = true;

        command = "${pkgs.notifications}/bin/notifications digest-flush";

        extraServiceConfig = {
          StartCalendarInterval = [
            {
              Hour = hourOf cfg.digest.at;
              Minute = minuteOf cfg.digest.at;
            }
          ];
        };
      };
    })

    (mkIf (cfg.digest.enable && pkgs.stdenv.isLinux) {
      systemd.user.services.notifications-digest = {
        Unit.Description = "Flush the shared notification digest to Discord";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.notifications}/bin/notifications digest-flush";
        };
      };

      systemd.user.timers.notifications-digest = {
        Unit.Description = "Daily notification digest flush";
        Timer = {
          OnCalendar = "*-*-* ${cfg.digest.at}:00";
          Persistent = true;
          Unit = "notifications-digest.service";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    })
  ];
}
