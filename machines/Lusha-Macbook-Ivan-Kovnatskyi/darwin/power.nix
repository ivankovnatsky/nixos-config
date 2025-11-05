{
  local.services.pmset = {
    enable = true;

    # Enable low power mode when on battery, disable when on AC
    powerMode = {
      battery = true; # Enable low power mode on battery
      ac = false; # Disable low power mode on AC power
    };
  };
}
