{ lib, ... }:

with lib;
{
  options.device = {
    name = mkOption {
      type = types.enum [
        "desktop"
        "mac"
      ];
      description = "Name of device";
      default = "desktop";
    };

    type = mkOption {
      type = types.enum [
        "desktop"
        "laptop"
        "server"
      ];
      description = "Type of device";
      default = "laptop";
    };

    monitorName = mkOption {
      type = types.enum [
        "DP-1"
        "DP-2"
        "DP-3"
      ];
      description = "Monitor name in Sway";
      default = "DP-1";
    };

    graphicsEnv = mkOption {
      type = types.enum [
        "xorg"
        "wayland"
      ];
      default = "wayland";
    };

    videoDriver = mkOption {
      type = types.enum [
        "amdgpu"
        "nvidia"
        "intel"
        "modesetting"
      ];
      default = "modesetting";
    };

    xorgDpi = mkOption {
      type = types.enum [
        192
        142
      ];
      default = 142;
    };
  };

  options.flags = {
    purpose = mkOption {
      type = types.enum [
        "home"
        "work"
      ];
      description = "Purpose of device";
      default = "home";
    };

    editor = mkOption {
      type = types.enum [
        "vim"
        "nvim"
      ];
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

    a3wIp = mkOption {
      type = types.str;
      description = "a3w IP address";
      default = "192.168.50.6";
    };

    homeWorkPath = mkOption {
      type = types.str;
      description = "Base path for work directories (git sources, password store, etc.)";
      default = "~";
    };

    hotkeys = {
      terminal = mkOption {
        type = types.enum [
          "kitty"
          "Terminal"
          "Ghostty"
        ];
        description = "Default terminal application";
        default = "kitty";
      };

      browser = mkOption {
        type = types.enum [
          "Safari"
          "Firefox"
          "Firefox Developer Edition"
          "Google Chrome"
        ];
        description = "Default browser application";
        default = "Safari";
      };

      shortcuts = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              key = mkOption {
                type = types.str;
                description = "Keyboard shortcut key";
              };
              app = mkOption {
                type = types.str;
                description = "Application name to launch";
              };
            };
          }
        );
        description = "Application shortcuts for Hammerspoon";
        default = [
          {
            key = "0";
            app = "Finder";
          }
          {
            key = "1";
            app = "kitty";
          }
          {
            key = "2";
            app = "Safari";
          }
          {
            key = "9";
            app = "System Settings";
          }
        ];
      };
    };

    apps = {
      vscode = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable VSCode/VSCodium";
        };
      };
    };
  };
}
