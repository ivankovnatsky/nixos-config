{ config, lib, pkgs, ... }:

let
  modifier = "Mod4";

  blackColorHTML = "#000000";
  whiteColorHTML = "#ffffff";

  laptopDevice = "eDP-1";
  monitorDevice = config.device.monitorName;

  lockCmd =
    "${pkgs.swaylock}/bin/swaylock --daemonize --show-failed-attempts --indicator-caps-lock --color '${blackColorHTML}'";
  idleCmd = ''
    ${pkgs.swayidle}/bin/swayidle -w \
        timeout 3600 "${lockCmd}" \
        timeout 600 "swaymsg 'output * dpms off'" \
        resume "swaymsg 'output * dpms on'" \
        before-sleep "${lockCmd}"'';

  gsettings = "${pkgs.glib}/bin/gsettings";
  gtkSettings = import ./gtk.nix { inherit config pkgs; };
  gnomeSchema = "org.gnome.desktop.interface";
  importGsettingsCmd = pkgs.writeShellScript "import_gsettings.sh" ''
    ${gsettings} set ${gnomeSchema} gtk-theme ${gtkSettings.gtk.theme.name}
    ${gsettings} set ${gnomeSchema} icon-theme ${gtkSettings.gtk.iconTheme.name}
    ${gsettings} set ${gnomeSchema} cursor-theme ${gtkSettings.gtk.gtk3.extraConfig.gtk-cursor-theme-name}
  '';

  isLaptop = config.device.type == "laptop";

  extraConfigSway = ''
    titlebar_border_thickness 0
    titlebar_padding 0

    seat seat0 xcursor_theme "${gtkSettings.gtk.gtk3.extraConfig.gtk-cursor-theme-name}"
    seat seat0 hide_cursor 60000
  '';

  autostart-script = pkgs.writeScriptBin "autostart" ''
    #!${pkgs.bash}/bin/bash

    ${pkgs.alacritty}/bin/alacritty -e ${pkgs.tmuxinator}/bin/tmuxinator start default &!
    ${pkgs.firefox}/bin/firefox &!
    chromium &!
  '';

in
{

  programs = {
    zsh = {
      shellAliases = {
        clipman-fzf = ''
          ${pkgs.clipman}/bin/clipman pick --print0 --tool=CUSTOM --tool-args="fzf --bind 'tab:up' --cycle --read0"
        '';
      };
    };
  };

  wayland.windowManager.sway = {
    enable = true;
    systemdIntegration = true;

    wrapperFeatures = {
      base = true;
      gtk = true;
    };

    config = {
      modifier = "${modifier}";

      startup = [
        { command = "exec dbus-update-activation-environment WAYLAND_DISPLAY"; }
        { command = "${pkgs.swaykbdd}/bin/swaykbdd"; }
        { command = "${idleCmd}"; }
        { command = "${importGsettingsCmd}"; }
        { command = "${autostart-script}/bin/autostart"; }
        { command = "exec ${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store 1>> /tmp/clipman.log 2>&1 &"; }
      ];

      output =
        if isLaptop then {
          "${laptopDevice}" = {
            scale = "1.5";
            pos = "4625,2328";
          };

          "${monitorDevice}" = {
            scale = "2";
            pos = "2705,2328";

          };
        } else {
          "*" = {
            scale = "2";
          };
        };

      fonts = {
        names = [ "${config.variables.fontGeneral}" ];
        size = 0.0;
      };

      terminal = "alacritty";
      menu = ''
        ${pkgs.bemenu}/bin/bemenu-run --list 3 -n -f --ifne -p "" --hb "${whiteColorHTML}" --hf "${blackColorHTML}"'';

      input =
        {
          "1:1:AT_Translated_Set_2_keyboard" = {
            xkb_layout = "us,ua";
            xkb_options = "grp:caps_toggle";
          };

          "2:10:TPPS/2_Elan_TrackPoint" = {
            accel_profile = "flat";
            pointer_accel = "-0.7";
          };

          "1739:52710:DLL0945:00_06CB:CDE6_Touchpad" = {
            natural_scroll = "enabled";
            middle_emulation = "enabled";
            tap = "enabled";
          };

          "2:7:SynPS\/2_Synaptics_TouchPad" = {
            natural_scroll = "enabled";
            middle_emulation = "enabled";
            accel_profile = "flat";
            pointer_accel = "-0.5";
          };

          "1241:274:USB-HID_Keyboard" = {
            xkb_layout = "us,ua";
            xkb_options = "grp:caps_toggle";
          };

          "5426:120:Razer_Razer_Viper" = {
            accel_profile = "flat";
            pointer_accel = "-0.7";
          };

          "1133:49271:Logitech_USB_Optical_Mouse" = {
            accel_profile = "flat";
            pointer_accel = "-0.7";
          };
        };

      keybindings = lib.mkOptionDefault {
        "Mod1+Control+Shift+4" = "exec grimshot --notify copy area";

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

      colors = {
        focused = {
          border = "#4c7899";
          background = whiteColorHTML;
          text = blackColorHTML;
          indicator = "#2e9ef4";
          childBorder = whiteColorHTML;
        };
      };

      window = {
        border = 1;
        hideEdgeBorders = "smart";
        titlebar = false;

        commands = [
          {
            command = "inhibit_idle visible, floating enable";
            criteria = {
              title = "(is sharing your screen)|(Sharing Indicator)";
            };
          }

          {
            command = "border pixel 1";
            criteria = { class = "^.*"; };
          }

          {
            command = "inhibit_idle fullscreen";
            criteria = { app_id = "(firefox|chromium-browser)"; };
          }
        ];
      };

      assigns = {
        "1" = [{ app_id = "Alacritty"; }];
        "2" = [{ app_id = "firefox"; }];
        "3" = [{ app_id = "chromium-browser"; }];
        "4" = [{ app_id = "google-chrome"; }];
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

        extraConfig = ''
          tray_output *
        '';

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

    extraConfig =
      if isLaptop then ''
        ${extraConfigSway}

        set $laptop ${laptopDevice}
        bindswitch --reload --locked lid:on output $laptop disable
        bindswitch --reload --locked lid:off output $laptop enable
        workspace 9 output ${laptopDevice}
      '' else ''
        ${extraConfigSway}
      '';
  };

  home.packages = with pkgs; [
    sway-contrib.grimshot
    wdisplays
    wl-clipboard
    wf-recorder
  ];
}
