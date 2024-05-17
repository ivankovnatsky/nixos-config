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
