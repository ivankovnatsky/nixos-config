{ ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      window.decorations = "none";

      font = {
        family = "Hack Nerd Font Mono";
        size = 12;
        draw_bold_text_with_bright_colors = true;
      };

      selection.save_to_clipboard = true;
      colors.primary.background = "#000000";

      cursor = {
        text = "#ffffff";
        cursor = "#FF7F50";
      };

      live_config_reload = true;
    };
  };
}
