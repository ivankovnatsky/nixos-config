{ pkgs, ... }:

{
  services = {
    xserver = {
      desktopManager.gnome3.enable = true;
      displayManager.gdm.enable = true;
    };
  };
}
