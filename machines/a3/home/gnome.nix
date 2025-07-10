{ config, lib, pkgs, ... }:

{
  # Enable dconf for GNOME settings
  dconf = {
    enable = true;
    settings = {
      # GNOME font settings
      "org/gnome/desktop/interface" = {
        "monospace-font-name" = "${config.flags.fontMono} 11";
        "font-name" = "${config.flags.fontGeneral} 11";
      };
      
      # GNOME Console settings
      "org/gnome/Console" = {
        "use-system-font" = false;
        "custom-font" = "${config.flags.fontGeneral} 11";
      };

      # Mouse settings - low acceleration
      "org/gnome/desktop/peripherals/mouse" = {
        # Set to flat profile (no acceleration)
        "accel-profile" = "flat";
        # Set speed to a lower value (between -1.0 and 1.0, where 0 is default)
        "speed" = -0.3;
      };
      
      # BUG: Hangs GNOME
      # Night Light (Night Shift) settings
      # "org/gnome/settings-daemon/plugins/color" = {
      #   # Enable Night Light
      #   "night-light-enabled" = true;
      #   # Set temperature to 3700K (warmer)
      #   "night-light-temperature" = 3700;
      #   # Use manual schedule instead of automatic sunset/sunrise
      #   "night-light-schedule-automatic" = false;
      #   # Set start time to 21:00 (9 PM)
      #   "night-light-schedule-from" = 21.0;
      #   # Set end time to 6:00 (6 AM)
      #   "night-light-schedule-to" = 6.0;
      # };
            
      # TODO: Dock settings
    };
  };
}
