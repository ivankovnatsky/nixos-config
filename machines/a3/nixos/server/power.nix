{ pkgs, ... }:

{
  systemd.timers.auto-poweroff = {
    description = "Daily auto power-off at 22:20";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 22:20:00";
      Persistent = false;
    };
  };

  systemd.services.auto-poweroff = {
    description = "Auto power-off";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.homelab}/bin/homelab auto-shutdown";
    };
  };

  systemd.timers.auto-poweroff-notify = {
    description = "Daily auto power-off notification at 22:10";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 22:10:00";
      Persistent = false;
    };
  };

  systemd.services.auto-poweroff-notify = {
    description = "Auto power-off notification";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.homelab}/bin/homelab auto-notify";
    };
  };
}
