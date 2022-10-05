{ config, pkgs, ... }:

let
  cursorThemeName = "capitaine-cursors";
  cursorSize = 16;

in
{
  home.packages = with pkgs; [
    capitaine-cursors
  ];

  gtk = {
    enable = true;

    theme.name = "Adwaita";

    iconTheme = {
      name = "Adwaita";
      package = pkgs.gnome.adwaita-icon-theme;
    };

    gtk2 = {
      extraConfig = ''
        gtk-application-prefer-dark-theme = true
        gtk-xft-antialias = 1
        gtk-xft-hinting = 1
        gtk-xft-hintstyle = "hintfull"
        gtk-cursor-theme-size = cursorSize
        gtk-cursor-theme-name = ${cursorThemeName}
      '';
    };

    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintfull";
        gtk-cursor-theme-size = cursorSize;
        gtk-cursor-theme-name = cursorThemeName;
      };
    };
  };
}
