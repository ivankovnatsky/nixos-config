{ config, lib, pkgs, ... }:

{
  # Trying out Plasma because it handles Steam games at higher than 1920x1080
  # resolutions much expected, whereas in GNOME all games are capped at that
  # resolution.

  # And overall I see that configuring Qt apps are much more pleasant than GNOME.
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm.enable = true;
    displayManager.sddm.wayland.enable = true;
  };

  # Enable KDE Partition Manager with proper D-Bus access
  # https://github.com/NixOS/nixpkgs/issues/273659#issuecomment-1852402674
  programs.partition-manager.enable = true;
}
