{ config, lib, pkgs, ... }:

let
  wifiDeviceName = "wlan0";

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
            chip = "*-isa-*";
            inputs = [ config.device.cpuTempPattern ];

            format = {
              full = "{max}";
              short = "";
            };
          };

        memBlock = {
          block = "memory";
          display_type = "memory";
          format_mem = "{mem_used}/{mem_total}";
        };

        swapBlock = {
          block = "memory";
          display_type = "swap";
          format_swap = "{swap_used}/{swap_total}";
        };

        diskBlock = {
          block = "disk_space";
          path = "/";
          alias = "/";
          info_type = "used";
          alert = 200;
          warning = 150;

          format = {
            full = "{icon} {used}/{total}";
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
          driver = "sway";
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
            memBlock
            swapBlock
            diskBlock
            netBlock
            batteryBlock
            kbdBlock
            soundBlock
            timeBlock
          ];
        };
      };
  };
}
