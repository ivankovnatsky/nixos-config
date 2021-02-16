{ pkgs, ... }:

{
  xsession.pointerCursor = {
    name = "Adwaita";
    package = pkgs.gnome3.adwaita-icon-theme;
    size = 32;
  };

  gtk = {
    enable = true;

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
      '';
    };

    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintfull";
      };
    };
  };
}
