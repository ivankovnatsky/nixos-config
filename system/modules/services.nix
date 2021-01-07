{ pkgs, ... }:

{

  services = {
    xl2tpd.enable = true;
    blueman.enable = true;
    fwupd.enable = true;

    strongswan = {
      enable = true;
      secrets = [ "ipsec.d/ipsec.nm-l2tp.secrets" ];
    };

    gvfs.enable = true;

    upower.enable = true;
  };

  systemd.user.services = {
    autocutsel-clipboard = {
      description = "Autocutsel sync CLIPBOARD";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Restart = "always";
        ExecStart = "${pkgs.autocutsel}/bin/autocutsel -selection CLIPBOARD";
      };
    };

    autocutsel-primary = {
      description = "Autocutsel sync PRIMARY";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Restart = "always";
        ExecStart = "${pkgs.autocutsel}/bin/autocutsel -selection PRIMARY";
      };
    };
  };
}
