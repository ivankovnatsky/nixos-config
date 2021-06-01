{ pkgs, ... }:

let
  wifiDeviceName = "wlan0";
  openWeatherMapCity = builtins.readFile ../.secrets/openweathermap/city;
  openWeatherMapApikey = builtins.readFile ../.secrets/openweathermap/token;

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

    bars = {
      top = {
        blocks = [

          {
            block = "custom";
            command = "echo '{\"icon\":\"tux\", \"text\": \"'$(uname -r)'\"}'";
            interval = "once";
            json = true;
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
            inputs = [ "CPU" ];

            format = {
              full = "{max}";
              short = "";
            };
          }

          {
            block = "custom";
            interval = 1;
            command =
              "echo '{\"icon\":\"fan\", \"text\": \"'$(cat /sys/class/hwmon/hwmon4/fan1_input)' RPM\"}'";
            json = true;
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
              full = "{icon}{used}/{total}";
              short = "";
            };
          }

          {
            block = "net";
            device = wifiDeviceName;
            hide_inactive = true;
            interval = 1;

            format = {
              full = "{speed_down} {speed_up} {signal_strength}";
              short = "";
            };
          }

          {
            block = "battery";
            driver = "upower";
            allow_missing = true;
            hide_missing = true;
          }

          {
            block = "keyboard_layout";
            driver = "sway";
            mappings = {
              "English (US)" = "🇺🇸";
              "Ukrainian (N/A)" = "🇺🇦";
            };
          }

          {
            block = "sound";
            format = "{output_name} {volume}";
            on_click = "pavucontrol --tab=3";
            mappings = {
              "@DEFAULT_SINK@" = "";
              "alsa_output.pci-0000_07_00.6.HiFi__hw_Generic_1__sink" =
                "";
              "alsa_output.usb-Kingston_HyperX_Virtual_Surround_Sound_00000000-00.pro-output-0" =
                "";
              "alsa_output.usb-Schiit_Audio_Bifrost_Gen_5-00.pro-output-0" =
                "";
              "alsa_output.usb-Lenovo_ThinkPad_USB-C_Dock_Gen2_USB_Audio_000000000000-00.pro-output-0" =
                "蓼";
            };
          }

          {
            block = "taskwarrior";
            interval = 60;
            format = "{count}";
            format_everything_done = "";

            filters = [{
              name = "today";
              filter = "+PENDING +OVERDUE or +DUETODAY";
            }];
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
              full =
                "{temp} {apparent}  {humidity} 煮 {wind_kmh} km/h {direction}";
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
              tux = "";
              fan = "";
              update = "";
              noupdate = "";
            };
          };

          theme = {
            name = "space-villain";
            overrides = { separator = ""; };
          };
        };
      };
    };
  };
}
