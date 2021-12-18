{
  networking = {
    useDHCP = false;
    networkmanager.enableStrongSwan = true;

    networkmanager = {
      dns = "none";
      enable = true;

      wifi.powersave = true;
    };
  };
}
