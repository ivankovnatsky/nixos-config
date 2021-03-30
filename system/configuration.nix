{ config, lib, pkgs, options, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ./general.nix
    ./graphics.nix
    ./greetd.nix
    ./hardware.nix
    ./nix.nix
    ./monitoring.nix
    ./packages.nix
    ./programs.nix
    ./services.nix

    <home-manager/nixos>
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball
      "https://github.com/nix-community/NUR/archive/master.tar.gz") {
        inherit pkgs;
      };
  };

  home-manager.useGlobalPkgs = true;
  home-manager.users.ivan = { ... }: {
    imports = [
      ../home/general.nix

      ../home/neovim/default.nix

      ../home/programs.nix

      ../home/alacritty.nix
      ../home/firefox.nix
      ../home/git.nix
      ../home/gtk.nix
      ../home/i3status.nix
      ../home/tmux.nix
      ../home/zsh.nix

      ../home/sway.nix
      ../home/mako.nix
    ];

    home.stateVersion = config.system.stateVersion;
  };

  nixpkgs.overlays = [ (import ./overlays/default.nix) ];

  networking = {
    hostName = "thinkpad";
    networkmanager.enableStrongSwan = true;
  };

  system.stateVersion = "21.03";
}
