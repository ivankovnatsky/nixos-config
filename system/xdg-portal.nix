{ pkgs, ... }:

{
  xdg = {
    portal = {
      enable = true;
      gtkUsePortal = true;

      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
    };
  };
}
