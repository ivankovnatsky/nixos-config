{ config, pkgs, ... }:

{
  imports = [
    ./default.nix

    ../modules/flags
  ];

  # https://github.com/NixOS/nixpkgs/issues/175875
  nixpkgs.config.allowBroken = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    gnupg
    git-crypt

    # https://github.com/LnL7/nix-darwin/pull/553#issuecomment-1348696468
    ncurses
    syncthing
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

  # Add shells installed by nix to /etc/shells file.
  # Run before applying:
  #
  # ```console
  # sudo mv /etc/shells /etc/shells..before-nix-darwin
  # ```
  #
  # Set default shell to fish:
  #
  # ```console
  # chsh -s /run/current-system/sw/bin/fish
  # ```
  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ] ++ lib.optionals config.flags.enableFishShell [ fish ];

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina



  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
