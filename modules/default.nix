{ config, pkgs, lib, ... }:

with lib; {
  options.device = {
    name = mkOption {
      type = types.enum [ "desktop" "mac" ];
      description = "Name of device";
      default = "desktop";
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
  };

  options.variables = {
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
