{ lib, pkgs, ... }:

{
  services = {
    xl2tpd.enable = true;
    fwupd.enable = true;
    gnome.gnome-keyring.enable = true;
    geoclue2.enable = true;
    journald.extraConfig = "SystemMaxUse=1G";

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    strongswan = {
      enable = true;
      secrets = [ "ipsec.d/ipsec.nm-l2tp.secrets" ];
    };
  };

  systemd = {
    sleep.extraConfig = ''
      HibernateMode=shutdown
    '';
  };

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = false;
    };
  };
}
