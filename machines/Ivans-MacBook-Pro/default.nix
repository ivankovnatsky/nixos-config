{ pkgs, ... }:

{
  imports = [
    ../../system/darwin.nix
    ../../modules/darwin/pam.nix
  ];


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
    ];

    casks = [
      "maccy"
      "elastio"
      "amethyst"
      "firefox"
      "font-hack-nerd-font"
      "hammerspoon"
      #
      "kitty"
      "chromium"
      # To use PC mouse with natural scrolling
      "mos"
      "rectangle"
      "stats"
      "orbstack"
      "protonvpn"
      "teamviewer"
      "vlc"
      # To be able to use background blur
      "zoom"
      "coconutbattery"
      "vmware-fusion"
    ];

    caskArgs = {
      no_quarantine = true;
    };

    masApps = {
      "1Password for Safari" = 1569813296;
      "Dark Reader for Safari" = 1438243180;
      "Bitwarden" = 1352778147;
    };
  };

  system = {
    defaults = {
      NSGlobalDomain = {
        AppleKeyboardUIMode = 3;
        _HIHideMenuBar = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        "com.apple.sound.beep.volume" = 0.000;
      };

      dock = {
        # Whether to automatically rearrange spaces based on most recent use.
        mru-spaces = false;
        autohide = true;
        # Don't show dock right after mouse coursor is moved to the bottom of
        # the screen. Default is 0.24.
        autohide-delay = 50.0;
        minimize-to-application = true;
        # Don't show indicators of currently running applications.
        show-process-indicators = false;
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
      self: super: {
        # terraform = super.callPackage ../../overlays/hashicorp-generic.nix {
        #   name = "terraform";
        #   version = "1.1.7";
        #   sha256 = "sha256-iRnO7jT2v7Fqbp/2HJX0BDw1xtcLId4n5aFTwZx+upw=";
        #   system = "aarch64-darwin";
        # };
        # terraform = super.callPackage ../../overlays/hashicorp-generic.nix {
        #   name = "terraform";
        #   version = "1.3.7";
        #   sha256 = "sha256-AdVT2197TPBym3JeRAJkPv3liEsdq/XrgK8yjOXkR88=";
        #   system = "aarch64-darwin";
        # };
        aws-sso-cli = super.callPackage ../../overlays/aws-sso-cli.nix { };

        istioctl = self.callPackage ../../overlays/istioctl.nix {
          name = "istioctl";
          version = "1.17.6";
          platform = "osx-arm64";
          sha256 = "sha256-3DcNqhexJ50P2AeNlQnOfO5a3307lIDq0bDSaGB6+TI=";
        };
        kor = self.callPackage ../../overlays/kor.nix { };
        atuin = self.callPackage ../../overlays/atuin.nix {
          inherit (pkgs.darwin.apple_sdk.frameworks) AppKit Security SystemConfiguration;
        };
      }
    )
  ];
}
