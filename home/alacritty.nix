{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  fontSizeT = 9.5;
  fontSize = if isDarwin then 13 else fontSizeT;

  decorations = if isDarwin then "buttonless" else "none";
in
{
  # https://github.com/alacritty/alacritty/blob/c682a357ec78f13d2e6222c83abfa9071d8a18f3/alacritty.yml
  # https://github.com/alacritty/alacritty-theme/blob/master/themes/xterm.yaml
  home.file = {
    ".config/alacritty/alacritty.yml" = {
      text = ''
        # XTerm's default colors
        colors:
          # Default colors
          primary:
            background: '0x000000'
            foreground: '0xffffff'
          # Normal colors
          normal:
            black:   '0x000000'
            red:     '0xcd0000'
            green:   '0x00cd00'
            yellow:  '0xcdcd00'
            blue:    '0x0000ee'
            magenta: '0xcd00cd'
            cyan:    '0x00cdcd'
            white:   '0xe5e5e5'

          # Bright colors
          bright:
            black:   '0x7f7f7f'
            red:     '0xff0000'
            green:   '0x00ff00'
            yellow:  '0xffff00'
            blue:    '0x5c5cff'
            magenta: '0xff00ff'
            cyan:    '0x00ffff'
            white:   '0xffffff'
        font:
          bold:
            family: "${config.variables.fontMono}"
          bold_italic:
            family: "${config.variables.fontMono}"
          draw_bold_text_with_bright_colors: true
          italic:
            family: "${config.variables.fontMono}"
          normal:
            family: "${config.variables.fontMono}"
          size: ${builtins.toString fontSize}
          offset:
            x: 1
            y: 4
        live_config_reload: true
        selection:
          save_to_clipboard: true
        window:
          decorations: ${decorations}
          padding:
            x: 5
            y: 0
      '';
    };
  };
}
