{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  fontSizeT = if config.device.graphicsEnv == "xorg" then 7.5 else 9.5;
  fontSize = if isDarwin then 13 else fontSizeT;

  githubTheme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/kovidgoyal/kitty-themes/master/themes/Github.conf";
    sha256 = "sha256-hGIgtYSAXztWehWagpPJhK64yX51GbKDNGlmQs6xnGQ=";
  };

  tangoTheme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dexpota/kitty-themes/master/themes/Tango_Light.conf";
    sha256 = "sha256-5jvlTAovkcVczwhTREalLIanlzjDRMbf+aT7jMOxDkU=";
  };

in
{
  home.file.".config/kitty/current-theme.conf".source = tangoTheme;

  # place it in ~/.config/kitty/current-theme.conf and add an include to kitty.conf
  home.file = {
    ".config/kitty/kitty.conf" = {
      text = ''
        ${if config.device.darkMode then ""
        else ''
            include current-theme.conf
        ''}

        font_family ${config.variables.fontGeneral}
        font_size ${builtins.toString fontSize}

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
