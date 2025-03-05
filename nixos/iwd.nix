{
  networking = {
    wireless.iwd.enable = true;
    wireless.iwd.settings.General.UseDefaultInterface = true;

    networkmanager = {
      wifi.backend = "iwd";
    };
  };
}
