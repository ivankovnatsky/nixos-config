{
  imports = [
    ../../system/darwin.nix
  ];

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
      # To use PC mouse with natural scrolling
      "mos"
      "coconutbattery"
      "font-hack-nerd-font"
    ];

    masApps = {
      "Bitwarden" = 1352778147;
      "NextDNS" = 1464122853;
    };
  };

  nixpkgs.overlays = [ ];
}
