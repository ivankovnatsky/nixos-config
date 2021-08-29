{ config, lib, pkgs, ... }:

let
  modifier = "Mod4";

  fontName = "Hack Nerd Font";
  blackColorHTML = "#000000";
  whiteColorHTML = "#ffffff";

in
{
  xsession.windowManager.i3 = {
    enable = true;

    config = {
      fonts = {
        names = [ "${fontName}" ];
        size = 0.0;
      };

      startup = [
        { command = "${pkgs.kbdd}/bin/kbdd"; }
        { command = "${pkgs.dunst}/bin/dunst"; }
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

      modifier = "${modifier}";

      keybindings = {
        "Mod1+Control+Shift+4" =
          ''exec --no-startup-id "maim -s | xclip -sel c -t image/png"'';

        "${modifier}+Control+Mod1+Shift+a" =
          "exec --no-startup-id autorandr all";
        "${modifier}+Control+Mod1+Shift+d" =
          "exec --no-startup-id autorandr default && xrandr --dpi 142 && i3-msg restart";
        "${modifier}+Control+Mod1+Shift+m" =
          "exec --no-startup-id autorandr monitor && xrandr --dpi 192 && i3-msg restart";

        "XF86MonBrightnessDown" =
          "exec --no-startup-id brightnessctl set 10%-";
        "XF86MonBrightnessUp" =
          "exec --no-startup-id brightnessctl set +10%";

        "XF86KbdBrightnessUp" =
          "exec --no-startup-id brightnessctl --device=tpacpi::kbd_backlight set +10%";
        "XF86KbdBrightnessDown" =
          "exec --no-startup-id brightnessctl --device=tpacpi::kbd_backlight set 10%-";

        "XF86AudioRaiseVolume" =
          "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "XF86AudioLowerVolume" =
          "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "XF86AudioMute" =
          "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioMicMute" =
          "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle";

        "${modifier}+Return" = "exec alacritty";
        "${modifier}+d" = "exec rofi -show run";

        "${modifier}+h" = "focus left";
        "${modifier}+l" = "focus right";

        "${modifier}+w" = "layout tabbed";
        "${modifier}+e" = "layout toggle split";

        "${modifier}+1" = "workspace number 1";
        "${modifier}+2" = "workspace number 2";
        "${modifier}+3" = "workspace number 3";
        "${modifier}+4" = "workspace number 4";

        "${modifier}+Shift+1" = "move container to workspace number 1";
        "${modifier}+Shift+2" = "move container to workspace number 2";
        "${modifier}+Shift+3" = "move container to workspace number 3";
        "${modifier}+Shift+4" = "move container to workspace number 4";

        "${modifier}+Shift+q" = "kill";
        "${modifier}+Shift+r" = "restart";

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
        "2" = [{ class = "^Firefox$"; }];
        "3" = [{ class = "^Chromium-browser$"; }];
      };

      bars = [{
        position = "top";
        fonts = {
          names = [ "${fontName}" ];
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

        trayOutput = "*";

        statusCommand =
          "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-top.toml";
      }];
    };
  };
}
