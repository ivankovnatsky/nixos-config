{ config, lib, pkgs, ... }:

let
  modifier = "Mod4";

  fontName = "Font Awesome 5 Free";
  blackColorHTML = "#000000";
  whiteColorHTML = "#ffffff";

in {
  home.sessionVariables = { };

  xsession.windowManager.i3 = {
    enable = true;

    config = {
      fonts = [ "${fontName} 0" ];

      startup = [{ command = "${pkgs.kbdd}/bin/kbdd"; }];

      colors = {
        focused = {
          border = "#4c7899";
          background = whiteColorHTML;
          text = "#ffffff";
          indicator = "#2e9ef4";
          childBorder = "#285577";
        };
      };

      modifier = "Mod4";

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
          "exec --no-startup-id brightnessctl --device=amdgpu_bl0 set 10%-";
        "XF86MonBrightnessUp" =
          "exec --no-startup-id brightnessctl --device=amdgpu_bl0 set +10%";

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

        "${modifier}+Return" = "exec alacritty -e tmuxinator start home";
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

      workspaceLayout = "tabbed";

      window = {
        hideEdgeBorders = "both";

        commands = [{
          command = "border pixel 1";
          criteria = { class = "^.*"; };
        }];

      };

      assigns = {
        "1" = [{ class = "^Alacritty$"; }];
        "2" = [{ class = "^Google-chrome$"; }];

        "4" = [
          { class = "^Pavucontrol$"; }
          { class = "^.blueman-manager-wrapped$"; }
        ];
      };

      bars = [{
        position = "top";
        fonts = [ "${fontName} 9" ];

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
