{ pkgs, ... }:

let cursorThemeName = "capitaine-cursors";

in {
  gtk = {
    enable = true;

    theme.name = "Adwaita";

    iconTheme = {
      name = "Adwaita";
      package = pkgs.gnome3.adwaita-icon-theme;
    };

    gtk2 = {
      extraConfig = ''
        gtk-application-prefer-dark-theme = true
        gtk-xft-antialias = 1
        gtk-xft-hinting = 1
        gtk-xft-hintstyle = "hintfull"
        gtk-cursor-theme-size = 16
        gtk-cursor-theme-name = ${cursorThemeName}
      '';
    };

    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintfull";
        gtk-cursor-theme-size = 16;
        gtk-cursor-theme-name = cursorThemeName;
      };
    };
  };
}
