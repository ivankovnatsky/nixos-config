{ pkgs, config, ... }:

{
  imports = [
    ../../system/darwin.nix
    ../../modules/darwin/pam
    ../../modules/darwin/dock

    ../../modules/secrets
  ];
  networking.hostName = "Ivans-MacBook-Air";
  flags = {
    enableFishShell = true;
    purpose = "home";
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
        # TODO:
        # * Tab layout: Compact tabs
        "com.apple.Safari" = {
          "ShowFullURLInSmartSearchField" = true;
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
  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
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
      "firefox"
      "eloston-chromium"
      "balenaetcher"
      "mullvadvpn"
      "vlc"
    ];
    masApps = {
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Bitwarden" = 1352778147;
      "Dark Reader for Safari" = 1438243180;
    };
    caskArgs = {
      no_quarantine = true;
    };
  };
  local = {
    dock.enable = true;
    # TODO: can dock be streched 100% horizontally?
    dock.entries = [
      { path = "/System/Applications/Launchpad.app/"; }
      { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
      { path = "/System/Applications/Messages.app/"; }
      { path = "/System/Applications/Mail.app/"; }
      { path = "/System/Applications/Maps.app/"; }
      { path = "/System/Applications/Photos.app/"; }
      { path = "/System/Applications/FaceTime.app/"; }
      { path = "/System/Applications/Calendar.app/"; }
      { path = "/System/Applications/Contacts.app/"; }
      { path = "/System/Applications/Reminders.app/"; }
      { path = "/System/Applications/Notes.app/"; }
      { path = "/System/Applications/TV.app/"; }
      { path = "/System/Applications/Music.app/"; }
      { path = "/System/Applications/Podcasts.app/"; }
      { path = "/System/Applications/App Store.app/"; }
      { path = "/System/Applications/System Settings.app/"; }

      { type = "spacer"; section = "apps"; }

      { path = "/System/Applications/Utilities/Terminal.app/"; }
      { path = "/System/Applications/Utilities/Activity Monitor.app/"; }
      { path = "/System/Applications/Passwords.app/"; }
      { path = "/System/Applications/iPhone Mirroring.app/"; }

      { type = "spacer"; section = "apps"; }

      { path = "/Applications/Firefox.app/"; }
      { path = "/Applications/Chromium.app/"; }
      { path = "/Applications/Bitwarden.app/"; }
      { path = "${pkgs.coconutbattery}/Applications/coconutBattery.app/"; }

      { type = "spacer"; section = "apps"; }

      # TODO: see if making a Dock web app could be automated.
      { path = "~/Applications/WhatsApp Web.app/"; }
      { path = "~/Applications/Telegram Web.app/"; }
      { path = "~/Applications/Claude.app/"; }
      { path = "~/Applications/ChatGPT.app/"; }
      { path = "~/Applications/Тривога.app/"; }

      {
        path = "${config.users.users."ivan".home}/Downloads/";
        section = "others";
      }
    ];
  };
  nixpkgs.overlays = [
    (
      self: super: {
        ks = super.callPackage ../../overlays/ks.nix { };
        coconutbattery = super.callPackage ../../overlays/coconutbattery.nix { };
        watchman-make = super.callPackage ../../overlays/watchman-make.nix { };
        battery-toolkit = super.callPackage ../../overlays/battery-toolkit.nix { };
      }
    )
  ];
}
