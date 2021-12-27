{
  networking = {
    useDHCP = false;

    networkmanager = {
      dns = "none";
      enable = true;

      wifi.powersave = true;
    };
  };
}
