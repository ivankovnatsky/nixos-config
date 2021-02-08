{ ... }:

let
  fontName = "Hack Nerd Font Mono 10";
  dpiNumber = 192;

in {
  programs.rofi = {
    enable = true;

    font = fontName;
    theme = "DarkBlue";

    extraConfig = { dpi = dpiNumber; };
  };
}

