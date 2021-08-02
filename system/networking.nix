{
  networking = {
    useDHCP = false;
    networkmanager.enableStrongSwan = true;
    wireless.iwd.enable = true;

    networkmanager = {
      enable = true;

      wifi.backend = "iwd";
      wifi.powersave = true;
    };
  };
}
