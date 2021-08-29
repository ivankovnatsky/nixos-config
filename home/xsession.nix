{ pkgs, ... }:

{
  xsession.pointerCursor = {
    name = "capitaine-cursors";
    package = pkgs.gnome3.adwaita-icon-theme;
    size = 64;
  };
}
