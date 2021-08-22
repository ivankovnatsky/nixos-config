{ config, pkgs, lib, ... }:

with lib; {
  options.device = {
    type = mkOption {
      type = types.enum [ "desktop" "laptop" ];
      description = "Type of device";
      default = "laptop";
    };

    cpuTempPattern = mkOption {
      type = types.enum [ "Package id 0" "CPU" ];
      description = "Type of CPU Temp search pattern in lensors command";
      default = "Package id 0";
    };

    monitorName = mkOption {
      type = types.enum [ "DP-2" "DP-3" ];
      description = "Monitor name in Sway";
      default = "DP-2";
    };
  };
}
