{ config, lib, pkgs, ... }:

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
        tuxBlock =
          {
            block = "custom";
            command = checkKernel;
            interval = "once";
            json = true;
          };

        cpuBlock = {
          block = "cpu";
          interval = 10;

          format = {
            full = "{utilization} {frequency}";
            short = "";
          };
        };

        loadBlock = {
          block = "load";
          interval = 10;

          format = {
            full = "{1m} {5m} {15m}";
            short = "";
          };
        };

        tempBlock =
          {
            block = "temperature";
            collapsed = false;

            format = {
              full = "{max:1}";
              short = "";
            };
          };

        fanBlock =
          if isLaptop then {
            block = "custom";
            command = checkFan;
            json = true;
          } else { };

        memBlock = {
          block = "memory";
          display_type = "memory";
          format_mem = "{mem_used:1}/{mem_total:1}";
        };

        swapBlock = {
          block = "memory";
          display_type = "swap";
          format_swap = "{swap_used:1}/{swap_total:1}";
        };

        diskBlock = {
          block = "disk_space";
          path = "/";
          alias = "/";
          info_type = "used";
          alert = 200;
          warning = 150;

          format = {
            full = "{icon} {used:1}/{total}";
            short = "{icon} {used:1}/{total}";
          };
        };

        netBlock = {
          block = "net";
          hide_inactive = true;
          interval = 10;

          format = {
            full = "{speed_down:1} {speed_up:1} {ssid} {signal_strength}";
            short = "";
          };
        };

        bluetoothBlock = {
          block = "bluetooth";
          mac = "CC:98:8B:D1:40:88";
          format = {
            full = "{percentage:1}";
            short = "";
          };
        };

        soundBlock = {
          block = "sound";
          on_click = "pavucontrol --tab=3";
          format = {
            full = "{volume}";
            short = "";
          };
        };

        batteryBlock =
          if isLaptop then {
            block = "battery";
            allow_missing = true;
            hide_missing = true;

            theme_overrides = {
              good_bg = "#06060f";
            };

          } else { };

        kbdBlock = {
          block = "keyboard_layout";
          driver = if config.device.graphicsEnv == "xorg" then "kbddbus" else "sway";
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
            full =
              "{temp} {apparent}  {humidity} 煮 {wind_kmh} km/h {direction}";
            short = "";
          };
        };

        timeBlock = {
          block = "time";
          format = "%a %b %d %H:%M";
        };

        settings = {
          icons = {
            name = "material-nf";

            overrides = {
              tux = "";
              fan = "";
              upd = "";
              noupd = "";
            };
          };

          theme = {
            name = "space-villain";
            overrides = { separator = ""; };
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
            fanBlock
            memBlock
            swapBlock
            diskBlock
            netBlock
            bluetoothBlock
            soundBlock
            batteryBlock
            kbdBlock
            weatherBlock
            timeBlock
          ];
        };
      };
  };
}
