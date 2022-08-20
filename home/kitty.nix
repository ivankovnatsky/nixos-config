{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  fontSizeT = if config.device.graphicsEnv == "xorg" then 7.5 else 9.5;
  fontSize = if isDarwin then 13 else fontSizeT;
in
{
  home.file = {
    ".config/kitty/kitty.conf" = {
      text = ''
        font_family ${config.variables.fontMono}
        font_size ${builtins.toString fontSize}

        hide_window_decorations titlebar-only
        cursor_blink_interval 0
      '';
    };
  };
}
