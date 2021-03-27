let
  fontName = "Hack Nerd Font Mono 10";
  dpiNumber = 192;
  blackColorHTML = "#000000";
  whiteColorHTML = "#ffffff";

in {
  programs.rofi = {
    enable = true;

    font = fontName;

    colors = {
      window = {
        background = blackColorHTML;
        border = whiteColorHTML;
        separator = "#c3c6c8";
      };

      rows = {
        normal = {
          background = blackColorHTML;
          foreground = whiteColorHTML;
          backgroundAlt = "#110d0d";
          highlight = {
            background = whiteColorHTML;
            foreground = blackColorHTML;
          };
        };
      };
    };

    extraConfig = { dpi = dpiNumber; };
  };
}
