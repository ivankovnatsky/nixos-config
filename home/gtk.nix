{ pkgs, ... }:

let
  cursorThemeName = "capitaine-cursors";
  cursorSize = 16;

in
{
  home.pointerCursor = {
    name = cursorThemeName;
    package = pkgs.capitaine-cursors;
    size = cursorSize;
    gtk.enable = true;
    x11.enable = true;
  };

  home.packages = with pkgs; [
    capitaine-cursors
  ];

  gtk = {
    enable = true;

    theme.name = "Adwaita";

    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
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
