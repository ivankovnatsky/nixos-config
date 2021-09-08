{ config, pkgs, lib, ... }:

with lib; {
  options.device = {
    name = mkOption {
      type = types.enum [ "thinkpad" "xps" "desktop" ];
      description = "Name of device";
      default = "thinkpad";
    };

    type = mkOption {
      type = types.enum [ "desktop" "laptop" ];
      description = "Type of device";
      default = "laptop";
    };

    cpuTempChip = mkOption {
      type = types.enum [ "thinkpad" "coretemp" ];
      description = "Type of CPU Temp chip pattern in i3status widget";
      default = "thinkpad";
    };

    cpuTempInput = mkOption {
      type = types.enum [ "Package id 0" "CPU" ];
      description = "Type of CPU Temp search pattern in i3status widget";
      default = "CPU";
    };

    monitorName = mkOption {
      type = types.enum [ "DP-2" "DP-3" ];
      description = "Monitor name in Sway";
      default = "DP-2";
    };

    graphicsEnv = mkOption {
      type = types.enum [ "xorg" "wayland" ];
      description = "";
      default = "wayland";
    };

    videoDriver = mkOption {
      type = types.enum [ "amdgpu" "nvidia" ];
      description = "";
      default = "nvidia";
    };
  };
}
