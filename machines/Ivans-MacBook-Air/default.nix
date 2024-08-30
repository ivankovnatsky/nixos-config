{ pkgs, ... }:

{
  imports = [
    ../../system/darwin.nix
    ../../modules/darwin/pam

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
        "com.apple.Safari" = {
          "ShowFullURLInSmartSearchField" = true;
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
      "balenaetcher"
      "mullvadvpn"
      "vlc"
    ];
    masApps = {
      "Numbers" = 409203825;
      "Bitwarden" = 1352778147;
    };
    caskArgs = {
      no_quarantine = true;
    };
  };
  nixpkgs.overlays = [
    (
      self: super: {
        ks = super.callPackage ../../overlays/ks.nix { };
        coconutbattery = super.callPackage ../../overlays/coconutbattery.nix { };
        watchman-make = super.callPackage ../../overlays/watchman-make.nix { };
      }
    )
  ];
}
