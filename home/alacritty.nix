let fontName = "Hack Nerd Font Mono";

in
{
  programs.alacritty = {
    enable = true;

    settings = {
      window.decorations = "none";

      font = {
        normal.family = fontName;
        bold.family = fontName;
        italic.family = fontName;
        bold_italic.family = fontName;

        size = 10;
        draw_bold_text_with_bright_colors = true;
      };

      selection.save_to_clipboard = true;
      colors.primary.background = "#000000";

      colors.cursor = {
        text = "#FFFFFF";
        cursor = "#FF7F50";
      };

      # does not work, until implemeted: https://github.com/alacritty/alacritty/pull/4322
      live_config_reload = true;
    };
  };
}
