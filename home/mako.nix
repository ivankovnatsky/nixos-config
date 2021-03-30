let
  fontName = "Hack Nerd Font Mono 10";
  blackColorHTML = "#000000";
  whiteColorHTML = "#ffffff";
  orangeColorHTML = "#ff7f50";

in {
  programs.mako = {
    enable = true;

    font = fontName;
    anchor = "top-right";

    backgroundColor = blackColorHTML;
    borderColor = orangeColorHTML;
    textColor = whiteColorHTML;

    borderRadius = 16;
    borderSize = 8;

    defaultTimeout = 10000;
    layer = "overlay";
  };
}
