{ config, lib, pkgs, ... }:

let
  modifier = "Mod4";

  fontSize = if config.device.xorgDpi == 192 then "20" else "14";

  blackColorHTML = "#000000";
  whiteColorHTML = "#ffffff";

  xidlehook-script = pkgs.writeScriptBin "xidlehook" ''
    xidlehook \
      --not-when-fullscreen \
      --not-when-audio \
      --timer 300 \
        'xset dpms force off' \
        ''' \
      --timer 1200 \
        'i3lock -c "#000000"' \
        '''
  '';

  autostart-script = pkgs.writeScriptBin "autostart" ''
    #!${pkgs.bash}/bin/bash

    ${pkgs.alacritty}/bin/alacritty -e ${pkgs.tmuxinator}/bin/tmuxinator start default &!
    ${pkgs.firefox}/bin/firefox &!
  '';
in
{
  home.packages = with pkgs; [
    xidlehook
    ffmpeg
  ];

  xsession.windowManager.i3 = {
    enable = true;

    config = {
      fonts = {
        names = [ "${config.variables.fontGeneral}" ];
        size = 0.0;
      };

      startup = [
        { command = "${pkgs.kbdd}/bin/kbdd"; }
        { command = "${xidlehook-script}/bin/xidlehook"; }
        { command = "${autostart-script}/bin/autostart"; }
      ];

      colors = {
        focused = {
          border = "#4c7899";
          background = whiteColorHTML;
          text = "#ffffff";
          indicator = "#2e9ef4";
          childBorder = "#285577";
        };
      };

      terminal = "alacritty";
      menu = ''
        ${pkgs.bemenu}/bin/bemenu-run --fn "${config.variables.fontGeneral} ${fontSize}" --list 3 -n -f --ifne -p "" --hb "${whiteColorHTML}" --hf "${blackColorHTML}"'';

      modifier = "${modifier}";

      keybindings = lib.mkOptionDefault {
        "Mod1+Control+Shift+4" =
          ''exec --no-startup-id "maim -s | xclip -sel c -t image/png"'';

        "${modifier}+Control+Mod1+Shift+a" =
          "exec --no-startup-id autorandr all";
        "${modifier}+Control+Mod1+Shift+d" =
          "exec --no-startup-id autorandr default && xrandr --dpi 142 && i3-msg restart";
        "${modifier}+Control+Mod1+Shift+m" =
          "exec --no-startup-id autorandr monitor && xrandr --dpi 192 && i3-msg restart";

        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k" = "focus up";
        "${modifier}+l" = "focus right";

        "XF86MonBrightnessDown" =
          "exec --no-startup-id brightnessctl set 10%-";
        "XF86MonBrightnessUp" =
          "exec --no-startup-id brightnessctl set +10%";

        "XF86AudioRaiseVolume" =
          "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "XF86AudioLowerVolume" =
          "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "XF86AudioMute" =
          "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioMicMute" =
          "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle";

        "Mod1+Tab" = "workspace back_and_forth";
      };

      window = {
        hideEdgeBorders = "both";

        commands = [{
          command = "border pixel 1";
          criteria = { class = "^.*"; };
        }];

      };

      assigns = {
        "1" = [{ class = "^Alacritty$"; }];
        "2" = [{ class = "^firefox$"; } { class = "^Chromium-browser$"; }];
        "3" = [{ class = "^Google-chrome$"; }];
        "8" = [
          { class = "^jetbrains-datagrip$"; }
        ];
      };

      workspaceLayout = "tabbed";

      bars = [{
        position = "top";
        fonts = {
          names = [ "${config.variables.fontGeneral}" ];
          size = 9.0;
        };

        colors = {

          focusedWorkspace = {
            border = whiteColorHTML;
            background = whiteColorHTML;
            text = blackColorHTML;
          };

          activeWorkspace = {
            border = "#5f676a";
            background = "#5f676a";
            text = "#ffffff";
          };

          inactiveWorkspace = {
            border = "#222222";
            background = "#222222";
            text = whiteColorHTML;
          };

          urgentWorkspace = {
            border = "#900000";
            background = "#900000";
            text = "#ffffff";
          };

        };

        statusCommand =
          "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-top.toml";
      }];
    };
  };
}
