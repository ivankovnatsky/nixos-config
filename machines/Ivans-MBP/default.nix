{ config, pkgs, ... }:

{
  imports = [
    ../../system/darwin.nix
    ../../modules/darwin/pam
    ../../modules/darwin/dock
    ../../modules/darwin/sudo

    ../../modules/secrets
  ];
  networking.hostName = "Ivans-MBP";
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
      "orbstack"
      "twingate"
      "kitty"
    ];
    masApps = {
      "1Password for Safari" = 1569813296;
      "Okta Verify" = 490179405;
      "Slack for Desktop" = 803453959;
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
        Defaults:ivan timestamp_timeout=240
      '';
    };
    dock.enable = true;
    # TODO: can dock be streched 100% horizontally?
    dock.entries = [
      { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
      { path = "/System/Applications/Mail.app/"; }
      { path = "/System/Applications/Calendar.app/"; }
      { path = "/System/Applications/Reminders.app/"; }
      { path = "/System/Applications/Notes.app/"; }
      { path = "/System/Applications/App Store.app/"; }
      { path = "/System/Applications/System Settings.app/"; }

      { type = "spacer"; section = "apps"; }

      { path = "/System/Applications/Utilities/Terminal.app/"; }
      { path = "/System/Applications/Utilities/Activity Monitor.app/"; }

      { type = "spacer"; section = "apps"; }

      { path = "/Applications/Firefox.app/"; }
      { path = "/Applications/Chromium.app/"; }
      { path = "/Applications/Slack.app/"; }

      { type = "spacer"; section = "apps"; }

      # TODO: see if making a Dock web app could be automated.
      { path = "~/Applications/Notion.app/"; }
      { path = "~/Applications/Claude.app/"; }
      { path = "~/Applications/ChatGPT.app/"; }
      { path = "~/Applications/Тривога.app/"; }

      { type = "spacer"; section = "apps"; }

      { path = "~/Applications/Chromium Apps.localized/Google Meet.app/"; }

      {
        path = "${config.users.users."ivan".home}/Downloads/";
        section = "others";
      }
    ];
  };

  nixpkgs.overlays = [
    (
      self: super: {
        watchman-make = super.callPackage ../../overlays/watchman-make.nix { };
        bclm = super.callPackage ../../overlays/bclm.nix { };
      }
    )
  ];
}
