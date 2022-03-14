{ config, pkgs, lib, ... }:

with lib; {
  options.device = {
    name = mkOption {
      type = types.enum [ "thinkpad" "xps" "desktop" ];
      description = "Name of device";
      default = "xps";
    };

    type = mkOption {
      type = types.enum [ "desktop" "laptop" ];
      description = "Type of device";
      default = "laptop";
    };

    monitorName = mkOption {
      type = types.enum [ "DP-1" "DP-2" "DP-3" ];
      description = "Monitor name in Sway";
      default = "DP-1";
    };

    graphicsEnv = mkOption {
      type = types.enum [ "xorg" "wayland" ];
      default = "wayland";
    };

    videoDriver = mkOption {
      type = types.enum [ "amdgpu" "nvidia" "intel" "modesetting" ];
      default = "modesetting";
    };

    xorgDpi = mkOption {
      type = types.enum [ 192 142 ];
      default = 142;
    };
  };

  options.variables = {
    nightShiftManager = mkOption {
      type = types.enum [ "gammastep" "redshift" ];
      default = "redshift";
    };

    fontGeneral = mkOption {
      type = types.str;
      default = "Hack Nerd Font";
    };

    fontMono = mkOption {
      type = types.str;
      default = "Hack Nerd Font Mono";
    };
  };
}
