{
  config,
  lib,
  pkgs,
  ...
}:

let
  isLaptop = config.device.type == "laptop";

  checkKernel = pkgs.writeShellScript "checkKernel" ''
    echo '{"icon":"tux", "text": "'$(uname -r)'"}'
  '';

  checkFan = pkgs.writeShellScript "checkFan" ''
    echo '{"icon":"fan", "text": "'$(cat /sys/class/hwmon/hwmon*/fan*_input)' RPM"}'
  '';

in
{
  xdg.configFile."i3status-rust/config-top.toml" = {
    onChange = ''
      if pgrep sway; then
        export SWAYSOCK=$(echo /run/user/1000/sway-ipc.*.sock)
        ${pkgs.sway}/bin/swaymsg reload || true
      else
        ${pkgs.i3}/bin/i3-msg restart || true
      fi
    '';
  };

  programs.i3status-rust = {
    enable = true;

    package = pkgs.i3status-rust;

    bars =
      let
        tuxBlock = {
          block = "custom";
          command = checkKernel;
          interval = "once";
          json = true;
        };

        cpuBlock = {
          block = "cpu";
          interval = 10;

          format = {
            full = "$icon $utilization$frequency ";
            short = "";
          };
        };

        loadBlock = {
          block = "load";
          interval = 10;

          format = {
            full = "$icon $1m.eng(w:4) $5m.eng(w:4) $15m.eng(w:4) ";
            short = "";
          };
        };

        tempBlock = {
          block = "temperature";

          format = {
            full = " $icon $max ";
            short = "";
          };
        };

        fanBlock = {
          block = "custom";
          command = checkFan;
          json = true;
        };

        memBlock = {
          block = "memory";
          format = " $icon $mem_used.eng(w:3,u:B,p:M)/$mem_total.eng(w:3,u:B,p:M) ";
        };

        swapBlock = {
          block = "memory";
          format = "$icon_swap $swap_used.eng(w:3,u:B,p:M)/$swap_total.eng(w:3,u:B,p:M) ";
        };

        diskBlock = {
          block = "disk_space";
          path = "/";
          info_type = "used";
          alert_unit = "GB";
          alert = 200.0;
          warning = 150.0;

          format = {
            full = "$icon $used/$total";
            short = "$icon $used/$total";
          };
        };

        netBlock = {
          block = "net";
          interval = 10;

          format = {
            full = " $icon $speed_down $speed_up $ssid $signal_strength";
            short = "";
          };
        };

        bluetoothBlock = {
          block = "bluetooth";
          mac = "CC:98:8B:D1:40:88";
          format = {
            full = "$icon $percentage";
            short = "";
          };
        };

        soundBlock = {
          block = "sound";
          click = [
            {
              button = "left";
              cmd = "pavucontrol --tab=3";
            }
          ];
          format = {
            full = "$icon $volume";
            short = "";
          };
        };

        batteryBlock = {
          block = "battery";
          missing_format = "";
        };

        kbdBlock = {
          block = "keyboard_layout";
          driver = "sway";
          mappings = {
            "English (US)" = "🇺🇸";
            "Ukrainian (N/A)" = "🇺🇦";
          };
        };

        weatherBlock = {
          block = "weather";
          service = {
            name = "openweathermap";
            api_key = "${config.secrets.openWeatherMapApikey}";
            place = "${config.secrets.openWeatherMapPlace}";
            units = "metric";
          };

          format = {
            full = "$icon $temp $apparent  $humidity  $wind_kmh km/h $direction";
            short = "";
          };
        };

        timeBlock = {
          block = "time";
          format = " $icon $timestamp.datetime(f:'%a %b %d %H:%M') ";
        };

        settings = {
          icons = {
            icons = "material-nf";
            overrides = {
              tux = "";
              fan = "";
              upd = "";
              noupd = "";
            };
          };

          theme = {
            theme = "space-villain";
            overrides = {
              separator = "";
            };
          };
        };
      in
      {
        top = {
          inherit settings;
          blocks = lib.lists.flatten [
            tuxBlock
            cpuBlock
            loadBlock
            tempBlock
            (if isLaptop then [ fanBlock ] else [ ])
            memBlock
            swapBlock
            diskBlock
            netBlock
            bluetoothBlock
            soundBlock
            (if isLaptop then [ batteryBlock ] else [ ])
            kbdBlock
            weatherBlock
            timeBlock
          ];
        };
      };
  };
}
