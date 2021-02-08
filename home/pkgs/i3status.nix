{ ... }:

let
  openWeatherMapApikey =
    builtins.readFile ../../../../../../.secrets/openweathermap;

in {
  programs.i3status-rust = {
    enable = true;

    bars = {
      top = {
        blocks = [

          {
            block = "cpu";
            interval = 1;
            format = "{utilization}% {frequency}GHz";
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
            command = "echo  $(cat /sys/class/hwmon/hwmon4/fan1_input) RPM";
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
          }

          {
            block = "net";
            device = "wlp3s0";
            hide_inactive = true;
            ip = false;
            speed_up = true;
            speed_down = true;
            graph_up = false;
            interval = 1;
            format = "{speed_down} {speed_up}";
          }

          {
            block = "keyboard_layout";
            driver = "kbddbus";
          }

          { block = "sound"; }

          {
            block = "battery";
            driver = "upower";
            format = "{percentage}%";
          }

          # {
          #   block = "taskwarrior";
          #   interval = 60;
          #   format = "{count} tasks";
          #   format_singular = "{count} task";
          #   format_everything_done = "nothing to do!";
          # }

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
            interval = 30;
            format = "%a %b %d %H:%M";
          }

        ];

        icons = "awesome5";
        theme = "native";
      };
    };
  };
}
