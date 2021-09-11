{ config, lib, pkgs, ... }:

let
  wifiDeviceName = "wlan0";
  openWeatherMapCity = builtins.readFile ../.secrets/openweathermap/city;
  openWeatherMapApikey = builtins.readFile ../.secrets/openweathermap/token;

  isLaptop = config.device.type == "laptop";

in
{
  xdg.configFile."i3status-rust/config-top.toml" = {
    onChange = ''
      export SWAYSOCK=$(echo /run/user/1000/sway-ipc.*.sock)
      ${pkgs.sway}/bin/swaymsg reload
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
            command = "echo '{\"icon\":\"tux\", \"text\": \"'$(uname -r)'\"}'";
            interval = "once";
            json = true;
          };

        cpuBlock = {
          block = "cpu";
          interval = 10;

          format = {
            full = "{barchart}";
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
            driver = "sysfs";

            format = {
              full = "{max:1}";
              short = "{max:1}";
            };
          };

        fanBlock =
          if isLaptop then {
            block = "custom";
            command =
              "echo '{\"icon\":\"fan\", \"text\": \"'$(cat /sys/class/hwmon/hwmon*/fan*_input)' RPM\"}'";
            json = true;
          } else { };

        memBlock = {
          block = "memory";
          display_type = "memory";
          format_mem = "{mem_used}/{mem_total:1}";
        };

        swapBlock = {
          block = "memory";
          display_type = "swap";
          format_swap = "{swap_used}/{swap_total:1}";
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
            short = "";
          };
        };

        netBlock = {
          block = "net";
          device = wifiDeviceName;
          hide_inactive = true;
          interval = 10;

          format = {
            full = "{graph_down} {graph_up} {signal_strength}";
            short = "";
          };
        };

        batteryBlock =
          if isLaptop then {
            block = "battery";
            allow_missing = true;
            hide_missing = true;
          } else { };

        kbdBlock = {
          block = "keyboard_layout";
          driver = if config.device.graphicsEnv == "xorg" then "kbddbus" else "sway";
          mappings = {
            "English (US)" = "🇺🇸";
            "Ukrainian (N/A)" = "🇺🇦";
          };
        };

        soundBlock = {
          block = "sound";
          format = "{volume}";
          on_click = "pavucontrol --tab=3";
        };

        weatherBlock = {
          block = "weather";
          service = {
            name = "openweathermap";
            api_key = "${openWeatherMapApikey}";
            city_id = "${openWeatherMapCity}";
            units = "metric";
          };

          format = {
            full =
              "{temp} {apparent}  {humidity} 煮 {wind_kmh} km/h {direction}";
            short = "";
          };
        };

        taskBlock = {
          block = "taskwarrior";
          format = "{count}";
          format_everything_done = "";

          filters = [{
            name = "today";
            filter = "+PENDING +OVERDUE or +DUETODAY";
          }];
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
            batteryBlock
            kbdBlock
            soundBlock
            taskBlock
            weatherBlock
            timeBlock
          ];
        };
      };
  };
}
