{ pkgs, ... }:

{
  services = {
    xserver.displayManager.gdm.enable = true;
    xserver.desktopManager.gnome3.enable = true;
  };
}
