{ config, pkgs, ... }:

{
  xsession.pointerCursor = {
    name = "capitaine-cursors";
    package = pkgs.gnome3.adwaita-icon-theme;
    size = if config.device.xorgDpi == 192 then 64 else 32;
  };
}
