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

  options.flags = {
    purpose = mkOption {
      type = types.enum [ "home" "work" ];
      description = "Purpose of device";
      default = "home";
    };

    editor = mkOption {
      type = types.enum [ "vim" "nvim" ];
      description = "Editor to use";
      default = "nvim";
    };

    darkMode = mkOption {
      type = types.bool;
      description = "Enable dark mode";
      default = true;
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

    git = {
      userName = mkOption {
        type = types.str;
        description = "Git user name";
        default = "Ivan Kovnatsky";
      };

      userEmail = mkOption {
        type = types.str;
        description = "Git user email";
        default = "75213+ivankovnatsky@users.noreply.github.com";
      };
    };
  };
}
