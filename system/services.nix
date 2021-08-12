{ lib, pkgs, ... }:

{
  services = {
    xl2tpd.enable = true;
    fwupd.enable = true;
    gnome.gnome-keyring.enable = true;
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
    services.NetworkManager-wait-online.enable = false;

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
