{ config
, lib
, pkgs
, ...
}:

{
  # systemd.timers.poweroff = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnCalendar = "*-*-* 22:30:00";
  #     Persistent = true;
  #   };
  # };

  # systemd.services.poweroff = {
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.systemd}/bin/poweroff";
  #   };
  # };

  # Enable Wake-on-LAN on the primary network interface
  networking.interfaces."enp1s0".wakeOnLan = {
    enable = true;
    # Specify which wake-on-lan policies to enable
    # Default is ["magic"] when enable = true
    # Other options include: "phy", "unicast", "multicast", "broadcast", "arp", "magic", "secureon"
    policy = [ "magic" ];
  };
}
