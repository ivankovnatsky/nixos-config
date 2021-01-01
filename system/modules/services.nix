{ ... }:

{
  services = {
    xl2tpd.enable = true;
    blueman.enable = true;

    strongswan = {
      enable = true;
      secrets = [ "ipsec.d/ipsec.nm-l2tp.secrets" ];
    };

    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
    };
  };
}
