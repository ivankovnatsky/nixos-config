{ lib, ... }:

with lib; {
  options.device = {
    name = mkOption {
      type = types.enum [ "desktop" "mac" ];
      description = "Name of device";
      default = "desktop";
    };

    type = mkOption {
      type = types.enum [ "desktop" "laptop" "server" ];
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
    purpose = mkOption {
      type = types.enum [ "home" "work" ];
      description = "Purpose of device";
      default = "home";
    };

    darkMode = mkOption {
      type = types.bool;
      description = "Enable dark mode";
      default = false;
    };

    fontGeneral = mkOption {
      type = types.str;
      default = "Hack Nerd Font";
    };

    fontMono = mkOption {
      type = types.str;
      default = "Hack Nerd Font Mono";
    };

    enableFishShell = mkOption {
      type = types.bool;
      description = "Enable fish shell";
      default = false;
    };
  };
}
