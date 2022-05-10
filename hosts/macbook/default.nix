{ config, lib, pkgs, options, ... }:

{
  imports = [
    ../../system/default.nix
    ../../modules/darwin/pam.nix

    ../../modules/default.nix
    ../../modules/secrets.nix
  ];

  security.pam.enableSudoTouchIdAuth = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    gnupg
    syncthing
    podman
    qemu
  ];

  environment.etc."containers/containers.conf.d/99-gvproxy-path.conf".text = ''
    [engine]
    helper_binaries_dir = ["${pkgs.gvproxy}/bin"]
  '';

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
        _HIHideMenuBar = true;
        NSAutomaticCapitalizationEnabled = false;
        "com.apple.sound.beep.volume" = "0.00";
      };

      dock = {
        autohide = true;
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

  homebrew.enable = true;
  homebrew.autoUpdate = false;
  homebrew.cleanup = "zap";
  homebrew.global.brewfile = true;
  homebrew.global.noLock = true;

  homebrew.taps = [
    "homebrew/cask"
    "homebrew/cask-fonts"
    "homebrew/core"
  ];

  homebrew.brews = [
    "pam-reattach"
  ];

  homebrew.casks = [
    "alacritty"
    "amethyst"
    "firefox"
    "font-hack-nerd-font"
    "google-chrome"
    "chromium"
    "hammerspoon"
  ];

  homebrew.masApps = {
    "NextDNS" = 1464122853;
  };
}
