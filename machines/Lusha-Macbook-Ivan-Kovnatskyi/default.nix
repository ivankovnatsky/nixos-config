{ config, pkgs, username, ... }:

let homePath = "${config.users.users.${username}.home}";

in
{
  imports = [
    ../../modules/darwin/dock
    ../../modules/darwin/pam
    ../../modules/darwin/sudo
    ../../modules/secrets
    ../../system
    ../../system/darwin.nix
  ];
  flags = {
    enableFishShell = true;
    purpose = "work";
    editor = "nvim";
    darkMode = true;
  };
  security.pamCustom.enableSudoTouchIdAuth = true;
  # Enable Low Power Mode:
  #
  # ```console
  # sudo pmset -a lowpowermode 1
  # ```
  system = {
    defaults = {
      controlcenter = {
        Bluetooth = false;
      };
      dock = {
        # https://github.com/LnL7/nix-darwin/blob/a35b08d09efda83625bef267eb24347b446c80b8/modules/system/defaults/dock.nix#L114
        mru-spaces = true;
      };
      NSGlobalDomain = {
        # Allow tab focus in all controls, space to select.
        AppleKeyboardUIMode = 3;
        # Repeatable space is killing me.
        InitialKeyRepeat = 120;
        KeyRepeat = 120;
      };
      CustomUserPreferences = {
        "NSGlobalDomain" = {
          # My keyboard does not support Globe switch key, or I don't know how
          # to use it, don't want to use karabiner-elements for now.
          "NSUserKeyEquivalents" = {
            "Move focus to active or next window" = "~`";
          };
        };
      };
    };
  };
  fonts.packages = with pkgs; [
    nerd-fonts.hack
  ];
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.cleanup = "zap";
    global.brewfile = true;
    brews = [
      # Since nix places it's new installs under newly generated nix store
      # path, we can't rely on nixpkgs pam-reattach, because after nixpkgs
      # upgrades PAM auth is broken for a common user. To fix it we need to
      # enable root user and edit /private/etc/pam.d/sudo to unblock auth.
      "pam-reattach"
    ];
    # Installed or managed using Kandji
    # google-chrome
    # zoom
    casks = [
      "amethyst"
      "bitwarden"
      "cursor"
      "dbeaver-community"
      "firefox"
      "hammerspoon"
      "kitty"
      "mindmac"
      "orbstack"
      "twingate"
      "windsurf"
      "zed"
    ];
    masApps = {
      # Installed using Kandji
      # "Okta Verify" = 490179405;
      # "Slack for Desktop" = 803453959;
      "Dark Reader for Safari" = 1438243180;
      "Okta Extension App" = 1439967473;
    };
    caskArgs = {
      no_quarantine = true;
    };
  };
  # https://github.com/kcrawford/dockutil
  local = {
    sudo = {
      enable = true;
      configContent = ''
        Defaults:${username} timestamp_timeout=240
      '';
    };
    dock.enable = true;
    # TODO: can dock be stretched 100% horizontally?
    dock.entries = [
      # Default macOS apps
      { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
      { path = "/System/Applications/Calendar.app/"; }
      { path = "/System/Applications/System Settings.app/"; }

      { type = "spacer"; section = "apps"; }

      # Additional macOS apps
      { path = "/System/Applications/Utilities/Terminal.app/"; }
      { path = "/System/Applications/Preview.app"; }
      { path = "/System/Library/CoreServices/Applications/Keychain Access.app"; }
      { path = "/System/Applications/Utilities/Activity Monitor.app/"; }

      { type = "spacer"; section = "apps"; }

      # Installed using Kandji
      { path = "/Applications/Google Chrome.app/"; }
      { path = "/Applications/Slack.app/"; }
      { path = "/Applications/zoom.us.app/"; }
      { path = "/Applications/DBeaver.app/"; }

      { type = "spacer"; section = "apps"; }

      # Installed using homebrew
      { path = "/Applications/kitty.app/"; }
      { path = "/Applications/Firefox.app/"; }
      { path = "/Applications/Zed.app/"; }
      { path = "/Applications/Cursor.app/"; }
      { path = "/Applications/Windsurf.app/"; }
      { path = "/Applications/MindMac.app/"; }
      { path = "/Applications/Bitwarden.app/"; }

      { type = "spacer"; section = "apps"; }

      # nixpkgs installed
      { path = "${pkgs.ghostty}/Applications/Ghostty.app/"; }
      { path = "${pkgs.vscode}/Applications/Visual Studio Code.app/"; }

      { type = "spacer"; section = "apps"; }

      # Safari Web Apps
      { path = "${homePath}/Applications/ChatGPT.app/"; }
      { path = "${homePath}/Applications/Claude.app/"; }

      {
        path = "${config.users.users.${username}.home}/Downloads/";
        section = "others";
      }
    ];
  };
}
