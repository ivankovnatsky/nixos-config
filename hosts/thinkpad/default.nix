{ config, lib, pkgs, options, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix

    ../../system/general.nix
    ../../system/greetd.nix
    ../../system/nix.nix
    ../../system/monitoring.nix
    ../../system/packages.nix
    ../../system/programs.nix
    ../../system/services.nix
  ];

  networking.hostName = "thinkpad";

  hardware = {
    # don't install all that firmware:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/all-firmware.nix
    enableAllFirmware = false;
    enableRedistributableFirmware = false;
    firmware = with pkgs; [ firmwareLinuxNonfree ];

    cpu.amd.updateMicrocode = true;
  };

  services = {
    upower = {
      enable = true;
      criticalPowerAction = "PowerOff";
    };

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
        CPU_MAX_PERF_ON_AC = 70;
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

  nixpkgs.overlays = [ (import ../../system/overlays/default.nix) ];

  system.stateVersion = "21.03";
}
