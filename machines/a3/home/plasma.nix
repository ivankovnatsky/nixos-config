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
          acceleration = -0.8; # Minimum possible value for slowest speed
        }
      ];
    };
  };
}
