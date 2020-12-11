{ ... }:

{
  services = {
    autorandr.enable = true;
    xl2tpd.enable = true;

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
