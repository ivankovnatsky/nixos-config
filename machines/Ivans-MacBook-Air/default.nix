{
  imports = [
    ../../system/darwin.nix
    ../../modules/darwin/pam.nix
  ];
  networking.hostName = "Ivans-MacBook-Air";
  variables = {
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
      "rectangle"
      "amethyst"
      # To use PC mouse with natural scrolling
      "mos"
      "coconutbattery"
      "font-hack-nerd-font"
      "stats"
    ];
    masApps = {
      "Numbers" = 409203825;
      "Bitwarden" = 1352778147;
    };
  };
  nixpkgs.overlays = [ ];
}
