{
  imports = [
    ../../system/darwin.nix
    ../../modules/darwin/pam
  ];
  networking.hostName = "Ivans-MacBook-Air";
  flags = {
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
    };
  };
  homebrew = {
    taps = [
      "homebrew/cask-fonts"
    ];
    brews = [
      # Since nix places it's new installs under newly generated nix store
      # path, we can't relay on nixpkgs pam-reattach, because after nixpkgs
      # upgrades PAM auth is broken for a common user. To fix it we need to
      # enable root user and edit /private/etc/pam.d/sudo to unblock auth.
      "pam-reattach"
    ];
    casks = [
      "firefox"
      "chromium"
      "rectangle"
      # To use PC mouse with natural scrolling
      "mos"
      "coconutbattery"
      "font-hack-nerd-font"
      "stats"
      "protonvpn"
      "orbstack"
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
      }
    )
  ];
}
