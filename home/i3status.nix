{ ... }:

let
  wifiDeviceName = "wlp2s0";
  openWeatherMapApikey =
    builtins.readFile ../../../../../.secrets/openweathermap;

in {
  programs.i3status-rust = {
    enable = true;

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
              "[ $(cut -c 16- /nix/var/nix/gcroots/current-system/nixos-version) != $(curl -s https://api.github.com/repos/NixOS/nixpkgs/git/refs/heads/nixos-unstable | jq '.object.sha' -r | cut -c 1-11) ] && echo '{\"icon\":\"update\",\"state\":\"Info\", \"text\": \"Update\"}' || echo '{\"icon\":\"noupdate\",\"state\":\"Idle\", \"text\": \"No Update\"}'";
            interval = 300;
            json = true;
          }

          {
            block = "cpu";
            interval = 1;
            format = "{utilization} {frequency}";
          }

          {
            block = "load";
            interval = 1;
            format = "{1m} {5m} {15m}";
          }

          {
            block = "temperature";
            collapsed = false;
            interval = 1;
            format = "{max}°";
            chip = "*-isa-*";
            inputs = [ "temp1" ];
          }

          {
            block = "custom";
            interval = 1;
            command = "echo  $(cat /sys/class/hwmon/hwmon4/fan1_input) RPM";
          }

          {
            block = "memory";
            display_type = "memory";
            format_mem = "{Mug}GiB/{MTg}GiB";
          }

          {
            block = "memory";
            display_type = "swap";
            format_swap = "{SUg}GiB/{STg}GiB";
          }

          {
            block = "disk_space";
            path = "/";
            alias = "/";
            info_type = "used";
            unit = "GiB";
            format = " {used}{unit}/{total}{unit}";
            alert = 200;
            warning = 150;
          }

          {
            block = "net";
            device = wifiDeviceName;
            hide_inactive = true;
            ip = false;
            speed_up = true;
            speed_down = true;
            graph_up = false;
            interval = 1;
            format = "{speed_down} {speed_up}";
          }

          {
            block = "battery";
            driver = "upower";
            format = "{percentage}%";
          }

          {
            block = "keyboard_layout";
            driver = "kbddbus";
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
            format = "{weather} {temp}°";
            autolocate = true;
            service = {
              name = "openweathermap";
              api_key = "${openWeatherMapApikey}";
              units = "metric";
            };
          }

          {
            block = "time";
            interval = 10;
            format = "%a %b %d %H:%M";
          }

        ];

        settings = {
          icons = {
            name = "awesome5";

            overrides = {
              update = "  ";
              noupdate = "  ";
            };
          };

          theme = {
            name = "space-villain";
            overrides = { separator = ""; };
          };
        };

        icons = "awesome5";
        theme = "space-villain";
      };
    };
  };
}
