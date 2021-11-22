{
  networking = {
    useDHCP = false;
    networkmanager.enableStrongSwan = true;
    wireless.iwd.enable = true;
    wireless.iwd.settings.General.UseDefaultInterface = true;

    networkmanager = {
      enable = true;

      wifi.backend = "iwd";
      wifi.powersave = true;
    };
  };
}
