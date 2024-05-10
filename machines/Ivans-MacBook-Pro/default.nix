{
  imports = [
    ../../system/darwin.nix
    ../../modules/darwin/pam
  ];

  networking.hostName = "Ivans-MacBook-Pro";

  flags = {
    purpose = "work";
    editor = "nvim";
    darkMode = false;
  };

  homebrew = {
    taps = [
      "homebrew/cask-fonts"
      "homebrew/services"
      "elastio/homebrew-tap"
      "boz/repo"
    ];

    # Install some packages through brew, since nixpkgs would require to
    # download huge tree of dependencies.
    brews = [
      # in nixpkgs
      # these 203 paths will be fetched (171.91 MiB download, 2050.54 MiB unpacked):
      "hadolint" # haskell
      "dockutil"
    ];

    casks = [
      "elastio"
      "amethyst"
      "firefox"
      "font-hack-nerd-font"
      "hammerspoon"
      "kitty"
      "chromium"
      # To use PC mouse with natural scrolling
      "mos"
      "rectangle"
      "stats"
      "coconutbattery"
      "zoom" # For recording
    ];

    masApps = {
      "Numbers" = 409203825;
      "1Password for Safari" = 1569813296;
      "NextDNS" = 1464122853;
    };

    caskArgs = {
      no_quarantine = true;
    };
  };

  system = {
    defaults = {
      NSGlobalDomain = {
        # Allow tab focus in all controls, space to select.
        AppleKeyboardUIMode = 3;
        _HIHideMenuBar = false;
        NSAutomaticCapitalizationEnabled = true;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        "com.apple.sound.beep.volume" = 0.000;
      };

      dock = {
        # Whether to automatically rearrange spaces based on most recent use.
        mru-spaces = false;
        autohide = false;
        # Don't show dock right after mouse coursor is moved to the bottom of
        # the screen. Default is 0.24.
        autohide-delay = 0.24;
        minimize-to-application = true;
        # Whether to show indicators of currently running applications.
        show-process-indicators = true;
      };

      finder = {
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
        FXEnableExtensionChangeWarning = false;
      };

      loginwindow = {
        GuestEnabled = false;
      };
    };
  };


  security.pamCustom.enableSudoTouchIdAuth = true;

  nixpkgs.overlays = [
    (
      self: super: { }
    )
  ];
}
