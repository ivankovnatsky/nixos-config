{ config, lib, pkgs, ... }:

{
  home.sessionVariables = { };

  xsession.windowManager.i3 = {
    enable = true;

    config = {
      fonts = [ "monospace 0" ];

      keybindings = {
        "Mod1+Control+Shift+4" =
          ''exec --no-startup-id "maim -s | xclip -sel c -t image/png"'';

        "Mod4+Control+Mod1+Shift+a" = "exec --no-startup-id autorandr all";
        "Mod4+Control+Mod1+Shift+l" =
          "exec --no-startup-id autorandr laptop && xrandr --dpi 142 && i3-msg restart";
        "Mod4+Control+Mod1+Shift+m" =
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
          "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10%";
        "XF86AudioLowerVolume" =
          "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10%";
        "XF86AudioMute" =
          "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioMicMute" =
          "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle";

        "Mod4+Shift+Return" = "exec alacritty -e tmuxinator start home";
        "Mod4+p" = "exec rofi -show run";

        "Mod4+j" = "focus left";
        "Mod4+k" = "focus right";

        "Mod4+w" = "layout tabbed";
        "Mod4+e" = "layout toggle split";

        "Mod4+1" = "workspace number 1";
        "Mod4+2" = "workspace number 2";
        "Mod4+3" = "workspace number 3";
        "Mod4+4" = "workspace number 4";

        "Mod4+Shift+1" = "move container to workspace number 1";
        "Mod4+Shift+2" = "move container to workspace number 2";
        "Mod4+Shift+3" = "move container to workspace number 3";
        "Mod4+Shift+4" = "move container to workspace number 4";

        "Mod4+Shift+c" = "kill";
        "Mod4+Shift+Control+r" = "restart";

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

        "3" = [
          { class = "^ViberPC$"; }
          { class = "^Signal$"; }
          { class = "^TelegramDesktop$"; }
          { class = "^Microsoft Teams - Preview$"; }
        ];

        "4" = [
          { class = "^Pavucontrol$"; }
          { class = "^.blueman-manager-wrapped$"; }
        ];
      };

      bars = [{
        trayOutput = "none";
        position = "top";
        fonts = [ "Font Awesome 5 Free 9" ];
        statusCommand =
          "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-top.toml";
      }];
    };
  };
}
