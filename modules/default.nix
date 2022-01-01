{ config, pkgs, lib, ... }:

with lib; {
  options.device = {
    name = mkOption {
      type = types.enum [ "thinkpad" "desktop" ];
      description = "Name of device";
      default = "thinkpad";
    };

    type = mkOption {
      type = types.enum [ "desktop" "laptop" ];
      description = "Type of device";
      default = "laptop";
    };

    monitorName = mkOption {
      type = types.enum [ "DP-2" "DP-3" ];
      description = "Monitor name in Sway";
      default = "DP-2";
    };

    graphicsEnv = mkOption {
      type = types.enum [ "xorg" "wayland" ];
      default = "wayland";
    };

    videoDriver = mkOption {
      type = types.enum [ "amdgpu" "nvidia" "intel" "modesetting" ];
      default = "nvidia";
    };

    xorgDpi = mkOption {
      type = types.enum [ 192 142 ];
      default = 192;
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
