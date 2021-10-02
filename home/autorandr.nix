{ config, pkgs, ... }:

let
  # thinkpad
  laptopFingerPrintThinkpad =
    "00ffffffffffff0006af3d5700000000001c0104a51f1178022285a5544d9a270e505400000001010101010101010101010101010101b43780a070383e401010350035ae100000180000000f0000000000000000000000000020000000fe0041554f0a202020202020202020000000fe004231343048414e30352e37200a0070";

  # xps
  laptopFingerPrintXps =
    "00ffffffffffff004d10f91400000000151e0104a51d12780ede50a3544c99260f505400000001010101010101010101010101010101283c80a070b023403020360020b410000018203080a070b023403020360020b410000018000000fe0056564b3859804c513133344e31000000000002410332001200000a010a20200080
";

  laptopFingerPrint = if config.device.name == "xps" then laptopFingerPrintXps else laptopFingerPrintThinkpad;

  monitorFingerPrint =
    "00ffffffffffff0010acbd404c363933241a0104a53c22783aee95a3544c99260f5054a54b00d100d1c0b300a94081808100714f01014dd000a0f0703e803020350055502100001a000000ff0056343857323639413339364c0a000000fc0044454c4c205032373135510a20000000fd001d4b1f8c36010a20202020202001e202031df150101f200514041312110302161507060123091f0783010000a36600a0f0701f803020350055502100001a565e00a0a0a029503020350055502100001a023a801871382d40582c450055502100001e011d007251d01e206e28550055502100001e000000000000000000000000000000000000000000000000000013";

  laptopIdentifier = if config.device.name == "xps" then "eDP-1" else "eDP";
  monitorIdentifier = if config.device.name == "xps" then "DP-3" else "DisplayPort-1";

in
{
  programs.autorandr = {
    enable = true;

    profiles = {
      "all" = {
        fingerprint = {
          "${laptopIdentifier}" = laptopFingerPrint;
          "${monitorIdentifier}" = monitorFingerPrint;
        };

        config = {
          "${laptopIdentifier}" = {
            enable = true;
            crtc = 0;
            mode = "1920x1080";
            position = "3840x0";
            primary = true;
            rate = "60.03";
          };

          "${monitorIdentifier}" = {
            enable = true;
            crtc = 1;
            primary = false;
            position = "0x0";
            mode = "3840x2160";
            rate = "60.00";
          };
        };

      };

      "default" = {
        fingerprint = {
          "${laptopIdentifier}" = laptopFingerPrint;
          "${monitorIdentifier}" = monitorFingerPrint;
        };

        config = {
          "${laptopIdentifier}" = {
            enable = true;
            crtc = 0;
            mode = "1920x1080";
            position = "0x0";
            primary = true;
            rate = "60.03";
          };

          "${monitorIdentifier}".enable = false;
        };

        hooks.postswitch = "xrandr --dpi 142";

      };

      "monitor" = {
        fingerprint = {
          "${laptopIdentifier}" = laptopFingerPrint;
          "${monitorIdentifier}" = monitorFingerPrint;
        };

        config = {
          "${laptopIdentifier}".enable = false;

          "${monitorIdentifier}" = {
            enable = true;
            crtc = 1;
            position = "0x0";
            mode = "3840x2160";
            rate = "60.00";
          };
        };

        hooks.postswitch = "xrandr --dpi 192";

      };
    };
  };
}
