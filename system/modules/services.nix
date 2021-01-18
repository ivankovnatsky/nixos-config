{ lib, pkgs, ... }:

{
  services = {
    xl2tpd.enable = true;
    blueman.enable = true;
    fwupd.enable = true;
    # gvfs.enable = true;

    strongswan = {
      enable = true;
      secrets = [ "ipsec.d/ipsec.nm-l2tp.secrets" ];
    };

    upower = {
      enable = true;
      criticalPowerAction = "PowerOff";
    };

    # udev.extraRules = lib.mkMerge [
    #   # autosuspend USB devices
    #   ''
    #     ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"''
    #   # autosuspend PCI devices
    #   ''
    #     ACTION=="add", SUBSYSTEM=="pci", TEST=="power/control", ATTR{power/control}="auto"''
    # ];

    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        # The following prevents the battery from charging fully to
        # preserve lifetime. Run `tlp fullcharge` to temporarily force
        # full charge.
        # https://linrunner.de/tlp/faq/battery.html#how-to-choose-good-battery-charge-thresholds
        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 50;

        # 100 being the maximum, limit the speed of my CPU to reduce
        # heat and increase battery usage:
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MAX_PERF_ON_BAT = 30;

        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;

        CONTROL_BRIGHTNESS = 1;
        BATT_BRIGHTNESS_COMMAND = "brightnessctl --device=amdgpu_bl0 set 20%";
        LM_AC_BRIGHTNESS_COMMAND = "brightnessctl --device=amdgpu_bl0 set 35%";
        NOLM_AC_BRIGHTNESS_COMMAND =
          "brightnessctl --device=amdgpu_bl0 set 35%";
        BRIGHTNESS_OUTPUT = "/sys/class/backlight/amdgpu_bl0/brightness";
      };
    };
  };

  systemd = {
    services.NetworkManager-wait-online.enable = false;

    user.services = {
      autocutsel-clipboard = {
        description = "Autocutsel sync CLIPBOARD";
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Restart = "always";
          ExecStart = "${pkgs.autocutsel}/bin/autocutsel -selection CLIPBOARD";
        };
      };

      autocutsel-primary = {
        description = "Autocutsel sync PRIMARY";
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Restart = "always";
          ExecStart = "${pkgs.autocutsel}/bin/autocutsel -selection PRIMARY";
        };
      };
    };
  };
}
