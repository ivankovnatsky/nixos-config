{ config, pkgs, ... }:

# FIXME: Add global user variable
let userName = "Ivan.Kovnatskyi";

in
{
  imports = [
    ../../system/darwin.nix
    ../../modules/darwin/pam
    ../../modules/darwin/dock
    ../../modules/darwin/sudo

    ../../modules/secrets
  ];
  users.users.${userName}.home = "/Users/${userName}";
  flags = {
    enableFishShell = true;
    purpose = "work";
    editor = "nvim";
    darkMode = true;
  };
  security.pamCustom.enableSudoTouchIdAuth = true;
  system = {
    defaults = {
      NSGlobalDomain = {
        # Allow tab focus in all controls, space to select.
        AppleKeyboardUIMode = 3;
      };
      CustomUserPreferences = {
        "NSGlobalDomain" = {
          # My keyboard does not support Globe switch key, or I don't know how
          # to use it, don't want to use karabiner-elements for now.
          "NSUserKeyEquivalents" = { };
        };
      };
    };
  };
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "Hack" ]; })
  ];
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.cleanup = "zap";
    global.brewfile = true;
    brews = [
      # Since nix places it's new installs under newly generated nix store
      # path, we can't relay on nixpkgs pam-reattach, because after nixpkgs
      # upgrades PAM auth is broken for a common user. To fix it we need to
      # enable root user and edit /private/etc/pam.d/sudo to unblock auth.
      "pam-reattach"
    ];
    casks = [
      "amethyst"
      "cursor"
      "claude"
      "kitty"
      "orbstack"
      "zed"
    ];
    masApps = { };
    caskArgs = {
      no_quarantine = true;
    };
  };
  # https://github.com/kcrawford/dockutil
  local = {
    sudo = {
      enable = true;
      configContent = ''
        Defaults:${userName} timestamp_timeout=240
      '';
    };
    dock.enable = true;
    # TODO: can dock be streched 100% horizontally?
    dock.entries = [
      { path = "/System/Applications/Launchpad.app/"; }
      { path = "/System/Applications/Calendar.app/"; }
      { path = "/System/Applications/System Settings.app/"; }

      { type = "spacer"; section = "apps"; }

      { path = "/System/Applications/Utilities/Activity Monitor.app/"; }

      { type = "spacer"; section = "apps"; }

      { path = "/Applications/Google Chrome.app/"; }
      { path = "/Applications/Slack.app/"; }
      { path = "/Applications/zoom.us.app/"; }
      { path = "/Applications/ChatGPT.app/"; }
      { path = "/Applications/DBeaver.app/"; }
      { path = "/Applications/Bitwarden.app/"; }

      { type = "spacer"; section = "apps"; }

      { path = "/Applications/kitty.app/"; }
      { path = "/Applications/Zed.app/"; }
      { path = "${pkgs.vscodium}/Applications/VSCodium.app/"; }
      { path = "/Applications/Cursor.app/"; }
      { path = "/Applications/Claude.app/"; }

      {
        path = "${config.users.users.${userName}.home}/Downloads/";
        section = "others";
      }
    ];
  };

  nixpkgs.overlays = [
    (
      self: super: {
        watchman-make = super.callPackage ../../overlays/watchman-make.nix { };
        battery-toolkit = super.callPackage ../../overlays/battery-toolkit.nix { };
        terragrunt-atlantis-config = super.callPackage ../../overlays/terragrunt-atlantis-config.nix { };
        gh-token = super.callPackage ../../overlays/gh-token.nix { };
      }
    )
  ];
}
