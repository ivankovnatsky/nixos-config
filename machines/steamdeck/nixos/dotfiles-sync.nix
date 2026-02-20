{
  pkgs,
  username,
  ...
}:
{
  systemd.services.dotfiles-sync = {
    description = "Dotfiles sync via bare repo";
    after = [ "network.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = username;
      ExecStart = "${pkgs.dotfiles}/bin/dotfiles home sync";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  systemd.timers.dotfiles-sync = {
    description = "Timer for dotfiles sync";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "*:0/15";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };
}
