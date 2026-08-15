{ config, ... }:

{
  systemd.timers.auto-poweroff = {
    description = "Daily auto power-off at 22:30";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 22:30:00";
      Persistent = false;
    };
  };

  systemd.services.auto-poweroff = {
    description = "Auto power-off";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.systemd.package}/bin/systemctl poweroff";
    };
  };
}
