{ config, lib, pkgs, ... }:

{
  services = {
    xl2tpd.enable = true;
    fwupd.enable = true;
    gnome.gnome-keyring.enable = true;
    journald.extraConfig = "SystemMaxUse=1G";
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
