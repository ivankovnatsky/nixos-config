{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  fontSizeT = if config.device.graphicsEnv == "xorg" then 7.5 else 9.5;
  fontSize = if isDarwin then 13 else fontSizeT;
in
{
  home.file = {
    ".config/kitty/kitty.conf" = {
      text = ''
        font_family ${config.variables.fontGeneral}
        font_size ${builtins.toString fontSize}

        adjust_line_height 115%
        hide_window_decorations titlebar-only
        cursor_blink_interval 0
        copy_on_select yes
        window_margin_width 0.5
        tab_bar_edge top
        max_title_length 100
        tab_title_template "{index}: {tab.active_exe}"
        macos_option_as_alt yes

        ${if isDarwin then ''
          map cmd+1 goto_tab 1
          map cmd+2 goto_tab 2
          map cmd+3 goto_tab 3
          map cmd+4 goto_tab 4
          map cmd+5 goto_tab 5
          map cmd+6 goto_tab 6
          map cmd+7 goto_tab 7
          map cmd+8 goto_tab 8
          map cmd+9 goto_tab 9
        ''
        else ""}
      '';
    };
  };
}
