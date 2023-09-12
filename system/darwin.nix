{ pkgs, ... }:

{
  imports = [
    ./default.nix
    ../modules/darwin/pam.nix

    ../modules/default.nix
    ../modules/secrets.nix
  ];

  # https://github.com/NixOS/nixpkgs/issues/175875
  nixpkgs.config.allowBroken = true;

  security.pamCustom.enableSudoTouchIdAuth = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    gnupg
    git-crypt

    # https://github.com/LnL7/nix-darwin/pull/553#issuecomment-1348696468
    ncurses
  ];

  device = {
    name = "mac";
  };

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  users.users.ivan.home = "/Users/ivan";

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

      screencapture.location = "~/Screenshots";

      dock = {
        # Whether to automatically rearrange spaces based on most recent use.
        mru-spaces = false;
        autohide = true;
        # Don't show dock right after mouse coursor is moved to the bottom of
        # the screen. Default is 0.24.
        autohide-delay = 2.0;
        minimize-to-application = true;
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

  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.cleanup = "zap";
    global.brewfile = true;

    taps = [
      "homebrew/cask"
      "homebrew/cask-fonts"
      "homebrew/core"
      "homebrew/services"
      "elastio/homebrew-tap"
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
    ];

    masApps = {
      "NextDNS" = 1464122853;
    };
  };
}
