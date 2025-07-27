{ config, lib, pkgs, ... }:

{
  # Configure mouse with slow speed using plasma-manager
  programs.plasma = {
    enable = true;
    # Configure input devices
    input = {
      mice = [
        # Only configure the main Razer Razer Viper entry
        {
          name = "Razer Razer Viper";
          vendorId = "1532"; # Razer vendor ID (hex)
          productId = "0078"; # Razer Viper product ID (hex)

          # Extremely slow mouse settings
          acceleration = -1.0; # Minimum possible value for slowest speed
        }
      ];
    };
    
    # Configure power management to use power saving mode
    powerdevil = {
      AC.powerProfile = "balanced";
    };
    
    # Configure taskbar with pinned applications
    panels = [
      {
        location = "top";
        height = 32;
        widgets = [
          {
            kickoff = {
            };
          }
          {
            iconTasks = {
              launchers = [
                "applications:org.kde.dolphin.desktop"
                "applications:org.kde.konsole.desktop"
                "applications:firefox-devedition.desktop"
                "applications:systemsettings.desktop"
              ];
            };
          }
          {
            systemTray.items = {
              shown = [
              ];
            };
          }
          {
            digitalClock = { };
          }
        ];
      }
    ];
  };
}
