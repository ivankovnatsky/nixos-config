{
  networking = {
    useDHCP = false;
    networkmanager.enableStrongSwan = true;

    networkmanager = {
      enable = true;

      wifi.powersave = true;
    };
  };
}
