{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  fontSizeT = if config.device.graphicsEnv == "xorg" then 7.5 else 9.5;
  fontSize = if isDarwin then 13 else fontSizeT;

in
{
  # Keybindings:
  # Ctrl + Shift + g -- opens a Pager of the last output
  # Ctrl + Shift + right click -- opens a Pager of the output under cursor
  home.file = {
    ".config/kitty/kitty.conf" = {
      # TODO: Add auto-theme switcher based on system appearance.
      text = ''
        ${if config.flags.darkMode then ""
        else ''
          cursor #808080
          background #ffffff
          foreground #000000
          color15 #d8d8c0
        ''}

        font_family ${config.flags.fontGeneral}
        font_size ${builtins.toString fontSize}

        macos_menubar_title_max_length 50
        # https://github.com/kovidgoyal/kitty/issues/3458#issuecomment-1312957967
        # Make it look more like Terminal.app
        # macos_thicken_font 0.5

        # font_size 13.75
        # modify_font cell_height 1.2
        # modify_font cell_width 95%
        # text_composition_strategy legacy

        allow_remote_control yes
        adjust_line_height 115%
        hide_window_decorations titlebar-only
        cursor_blink_interval 0
        copy_on_select yes
        draw_minimal_borders yes
        tab_bar_edge top
        tab_title_template "{index}: {tab.active_exe}"
        macos_option_as_alt yes

        enabled_layouts tall, grid

        map ctrl+shift+k neighboring_window up
        map ctrl+shift+j neighboring_window down
        map ctrl+shift+h neighboring_window left
        map ctrl+shift+l neighboring_window right

        map ctrl+shift+up neighboring_window up
        map ctrl+shift+down neighboring_window down
        map ctrl+shift+left neighboring_window left
        map ctrl+shift+right neighboring_window right

        # This is the remap of default value
        # Was ctrl+shift+l
        map ctrl+shift+space next_layout

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
