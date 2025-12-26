{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;
  fontSizeT = if config.device.graphicsEnv == "xorg" then 7.5 else 9.5;
  fontSize = if isDarwin then 13 else fontSizeT;
  windowPaddingWidth = if isDarwin then 8 else 4;

  # Keybindings:
  # Ctrl + Shift + g -- opens a Pager of the last output
  # Ctrl + Shift + right click -- opens a Pager of the output under cursor
  # Base kitty config

  # FIXME: Remove ctrl+shift+6 and other related keybinds, vim prev buffer.
  # https://sw.kovidgoyal.net/kitty/conf/
  kittyConfig = ''
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
    window_padding_width ${builtins.toString windowPaddingWidth}
    hide_window_decorations titlebar-only
    cursor_blink_interval 0
    copy_on_select yes
    draw_minimal_borders yes
    tab_bar_edge top
    tab_title_template "{index}: {tab.active_exe}"
    macos_option_as_alt yes

    # Shell integration for tracking pwd in new tabs
    shell_integration enabled

    # Action alias for launching tabs in current directory
    action_alias launch_tab launch --cwd=current --type=tab

    enabled_layouts tall, grid

    map ctrl+shift+k neighboring_window up
    map ctrl+shift+j neighboring_window down
    map ctrl+shift+h neighboring_window left
    map ctrl+shift+l neighboring_window right

    map ctrl+shift+up neighboring_window up
    map ctrl+shift+down neighboring_window down
    map ctrl+shift+left neighboring_window left
    map ctrl+shift+right neighboring_window right

    # Clear ctrl+shift+6 mapping to allow it to pass through to vim for buffer navigation
    map ctrl+shift+6 no_op

    # This is the remap of default value
    # Was ctrl+shift+l
    map ctrl+shift+space next_layout

    # New tab in current directory
    map kitty_mod+t launch_tab

    ${
      if isDarwin then
        ''
          map cmd+t launch_tab
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
      else
        ''
          map ctrl+1 goto_tab 1
          map ctrl+2 goto_tab 2
          map ctrl+3 goto_tab 3
          map ctrl+4 goto_tab 4
          map ctrl+5 goto_tab 5
          map ctrl+6 goto_tab 6
          map ctrl+7 goto_tab 7
          map ctrl+8 goto_tab 8
          map ctrl+9 goto_tab 9
        ''
    }
  '';

in
{
  # Install kitty package on Linux only, use Homebrew on macOS
  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.isLinux [
      kitty
    ];

  home.file = {
    ".config/kitty/kitty.conf" = {
      text = kittyConfig;
    };

    # Automatic theme switching (requires kitty 0.38.0+)
    # Inspired by https://github.com/nix-community/home-manager/blob/master/modules/programs/kitty.nix
    # References:
    # - https://gist.github.com/eg-ayoub/0066d7bbc4456ef5d06b8277437dc0dd
    # - https://sw.kovidgoyal.net/kitty/kittens/themes/#change-color-themes-automatically-when-the-os-switches-between-light-and-dark
    # Browse themes: ls ${pkgs.kitty-themes}/share/kitty-themes/themes/
    ".config/kitty/dark-theme.auto.conf" = {
      text = ''
        include ${pkgs.kitty-themes}/share/kitty-themes/themes/default.conf
      '';
    };

    ".config/kitty/light-theme.auto.conf" = {
      text = ''
        include ${pkgs.kitty-themes}/share/kitty-themes/themes/GitHub_Light.conf
      '';
    };

    # For GNOME, no-preference is treated as light mode
    ".config/kitty/no-preference-theme.auto.conf" = {
      text = ''
        include ${pkgs.kitty-themes}/share/kitty-themes/themes/Tokyo_Night_Moon.conf
      '';
    };
  };
}
