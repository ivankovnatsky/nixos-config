{ lib, pkgs, ... }:

{
  services = {
    acpid.enable = true;
    xl2tpd.enable = true;
    fwupd.enable = true;
    gnome.gnome-keyring.enable = true;
    clipmenu.enable = true;
    journald.extraConfig = "SystemMaxUse=1G";

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
