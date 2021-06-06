{
  services = {
    tlp = {
      enable = true;

      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CONTROL_BRIGHTNESS = 1;
        BATT_BRIGHTNESS_COMMAND = "brightnessctl set 20%";
        LM_AC_BRIGHTNESS_COMMAND = "brightnessctl set 35%";
        NOLM_AC_BRIGHTNESS_COMMAND =
          "brightnessctl set 35%";
        BRIGHTNESS_OUTPUT = "/sys/class/backlight/amdgpu_bl0/brightness";
      };
    };
  };
}
