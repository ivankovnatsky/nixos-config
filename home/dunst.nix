{ ... }:

let
  fontName = "Hack Nerd Font Mono 10";
  blackColorHTML = "#000000";
  whiteColorHTML = "#ffffff";
  orangeColorHTML = "#ff7f50";

in {
  services.dunst = {
    enable = true;

    settings = {
      experimantal.per_monitor_dpi = true;

      global = {
        corner_radius = 16;
        follow = "mouse";
        font = fontName;
        # escape \n with \
        format = "<b>%s</b>\\n%b";
        frame_color = orangeColorHTML;
        frame_width = 8;
        geometry = "1000x10-20+60";
        horizontal_padding = 8;
        icon_position = "off";
        ignore_newlines = false;
        markup = "full";
        padding = 8;
        show_indicators = false;
        shrink = false;
        word_wrap = true;
      };

      urgency_critical = {
        background = blackColorHTML;
        foreground = whiteColorHTML;
        timeout = 10;
      };

      urgency_low = {
        background = blackColorHTML;
        foreground = whiteColorHTML;
        timeout = 10;
      };

      urgency_normal = {
        background = blackColorHTML;
        foreground = whiteColorHTML;
        timeout = 10;
      };
    };
  };
}
