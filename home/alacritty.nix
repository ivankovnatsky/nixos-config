{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  fontSizeT = if config.device.graphicsEnv == "xorg" then 7.5 else 9.5;
  fontSize = if isDarwin then 13 else fontSizeT;
in
{
  home.file = {
    ".config/alacritty/alacritty.yml" = {
      text = ''
        {
          "colors": {
            "primary": {
              "background": "#000000"
            }
          },
          "font": {
            "bold": {
              "family": "${config.variables.fontMono}"
            },
            "bold_italic": {
              "family": "${config.variables.fontMono}"
            },
            "draw_bold_text_with_bright_colors": true,
            "italic": {
              "family": "${config.variables.fontMono}"
            },
            "normal": {
              "family": "${config.variables.fontMono}"
            },
            "size": ${builtins.toString fontSize}
          },
          "live_config_reload": true,
          "selection": {
            "save_to_clipboard": true
          },
          "window": {
            "decorations": "none"
          }
        }
      '';
    };
  };
}
