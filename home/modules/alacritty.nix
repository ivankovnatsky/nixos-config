{ ... }:

let fontName = "Hack Nerd Font Mono";

in {
  programs.alacritty = {
    enable = true;
    settings = {
      window.decorations = "none";

      font = {
        normal.family = fontName;
        bold.family = fontName;
        italic.family = fontName;
        bold_italic.family = fontName;

        size = 12;
        draw_bold_text_with_bright_colors = true;
      };

      selection.save_to_clipboard = true;
      colors.primary.background = "#000000";

      cursor = {
        cursor = "#FFFFFF";
        text = "#FF7F50";
      };

      live_config_reload = true;
    };
  };
}
