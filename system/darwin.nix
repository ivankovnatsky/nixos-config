{ config, lib, pkgs, options, ... }:

{
  imports = [
    ./default.nix
    ../modules/darwin/pam.nix

    ../modules/default.nix
    ../modules/secrets.nix
  ];

  # https://github.com/NixOS/nixpkgs/issues/175875
  nixpkgs.config.allowBroken = true;

  security.pam.enableSudoTouchIdAuth = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    gnupg
    git-crypt
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
        _HIHideMenuBar = true;
        NSAutomaticCapitalizationEnabled = false;
        "com.apple.sound.beep.volume" = "0.000";
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
    "homebrew/services"
  ];

  # Install some packages through brew, since using nixpkgs we sometimes need
  # to download huge tree of dependencies
  homebrew.brews = [
    "hadolint" # haskell
    "awscli"
    "syncthing"
    "pam-reattach"
  ];

  # Docker Desktop installs all bunch of kube and container tools, so no need to install
  # kubectl and others
  homebrew.casks = [
    "iterm2"
    "1password-cli"
    "1password"
    "docker"
    "amethyst"
    "firefox"
    "font-hack-nerd-font"
    "hammerspoon"
    "mos"
  ];

  homebrew.masApps = {
    "Bitwarden" = 1352778147;
    "NextDNS" = 1464122853;
  };
}
