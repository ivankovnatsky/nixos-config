{ config, pkgs, ... }:

{
  # Vanilla dwm with no patches or customizations
  services.xserver.windowManager.dwm.enable = true;
  
  # Basic utilities for dwm
  environment.systemPackages = with pkgs; [
    dmenu
    st
  ];

  # Optional: Auto-login for testing
  # services.xserver.displayManager.autoLogin = {
  #   enable = true;
  #   user = "ivan";
  # };
}