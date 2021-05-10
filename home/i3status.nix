{ pkgs, ... }:

let
  wifiDeviceName = "wlp2s0";
  openWeatherMapCity =
    builtins.readFile ../../../../../.secrets/openweathermap_city;
  openWeatherMapApikey =
    builtins.readFile ../../../../../.secrets/openweathermap;

in {
  programs.i3status-rust = {
    enable = true;

    package = pkgs.i3status-rust;

    bars = {
      top = {
        blocks = [

          {
            block = "custom";
            command = "echo  $(uname -r)";
            interval = "once";
          }

          {
            block = "custom";
            command =
              "[ $(nixos-version --revision) != $(curl -s https://api.github.com/repos/NixOS/nixpkgs/git/refs/heads/nixos-unstable | jq '.object.sha' -r ) ] && echo '{\"icon\":\"update\",\"state\":\"Info\", \"text\": \"Update\"}' || echo '{\"icon\":\"noupdate\",\"state\":\"Idle\", \"text\": \"No Update\"}'";
            interval = 1800;
            json = true;
          }

          {
            block = "cpu";
            interval = 1;

            format = {
              full = "{utilization} {frequency}";
              short = "";
            };
          }

          {
            block = "load";
            interval = 1;

            format = {
              full = "{1m} {5m} {15m}";
              short = "";
            };
          }

          {
            block = "temperature";
            collapsed = false;
            interval = 1;
            chip = "*-isa-*";
            inputs = [ "temp1" ];

            format = {
              full = "{max}";
              short = "";
            };
          }

          {
            block = "custom";
            interval = 1;
            command = "echo  $(cat /sys/class/hwmon/hwmon4/fan1_input) RPM";
          }

          {
            block = "memory";
            display_type = "memory";
            format_mem = "{mem_used}/{mem_total}";
          }

          {
            block = "memory";
            display_type = "swap";
            format_swap = "{swap_used}/{swap_total}";
          }

          {
            block = "disk_space";
            path = "/";
            alias = "/";
            info_type = "used";
            alert = 200;
            warning = 150;

            format = {
              full = " {used}/{total}";
              short = "";
            };
          }

          {
            block = "net";
            device = wifiDeviceName;
            hide_inactive = true;
            interval = 1;

            format = {
              full = "{speed_down} {speed_up}";
              short = "";
            };
          }

          {
            block = "battery";
            driver = "upower";
          }

          {
            block = "keyboard_layout";
            driver = "sway";
            format = " {layout}";
          }

          {
            block = "sound";
            on_click = "pavucontrol";
          }

          {
            block = "taskwarrior";
            interval = 60;
            format = "{count} tasks";
            format_singular = "{count} task";
            format_everything_done = "nothing to do!";
          }

          {
            block = "weather";

            service = {
              name = "openweathermap";
              api_key = "${openWeatherMapApikey}";
              city_id = "${openWeatherMapCity}";
              units = "metric";
            };

            format = {
              full = "{temp} {apparent}  {humidity} 煮 {wind_kmh} km/h";
              short = "";
            };
          }

          {
            block = "time";
            format = "%a %b %d %H:%M";
          }

        ];

        settings = {
          icons = {
            name = "material-nf";

            overrides = {
              update = "";
              noupdate = "";
            };
          };

          theme = {
            name = "space-villain";
            overrides = { separator = ""; };
          };
        };

        icons = "material-nf";
        theme = "space-villain";
      };
    };
  };
}
