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
    darkMode = false;
  };
  security.pamCustom.enableSudoTouchIdAuth = true;
  system = {
    defaults = {
      NSGlobalDomain = {
        # Allow tab focus in all controls, space to select.
        AppleKeyboardUIMode = 3;
      };
      CustomUserPreferences = {
        "com.apple.Safari" = {
          "ShowFullURLInSmartSearchField" = true;
          "AutoShowToolbarInFullScreen" = true;
        };
        "NSGlobalDomain" = {
          # My keyboard does not support Globe switch key, or I don't know how
          # to use it, don't want to use karabiner-elements for now.
          "NSUserKeyEquivalents" = {
            "Center" = "@~^c";
            "Fill" = "@~^f";
            "Right" = "@~^→";
            "Left" = "@~^←";
            "Return to Previous Size" = "@~^r";
          };
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
      "openlens"
      "orbstack"
      "zed"
      "vscodium"
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
      { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
      { path = "/System/Applications/System Settings.app/"; }

      { type = "spacer"; section = "apps"; }

      { path = "/System/Applications/Utilities/Terminal.app/"; }
      { path = "/System/Applications/Utilities/Activity Monitor.app/"; }
      { path = "/System/Applications/Passwords.app/"; }

      { type = "spacer"; section = "apps"; }

      { path = "/Applications/Kandji Self Service.app/"; }
      { path = "/Applications/Firefox.app/"; }
      { path = "/Applications/Google Chrome.app/"; }
      { path = "/Applications/Slack.app/"; }
      { path = "/Applications/zoom.us.app/"; }
      { path = "/Applications/ChatGPT.app/"; }
      { path = "/Applications/DBeaver.app/"; }
      { path = "/Applications/Zed.app/"; }
      { path = "/Applications/VSCodium.app/"; }
      { path = "/Applications/Bitwarden.app/"; }

      { type = "spacer"; section = "apps"; }

      # TODO: see if making a Dock web app could be automated.
      { path = "~/Applications/Claude.app/"; }
      # { path = "~/Applications/ChatGPT.app/"; }

      {
        # FIXME:
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
      }
    )
  ];
}
