{ config, pkgs, ... }:

{
  imports = [
    ../../modules/flags

    ../../home/firefox-config.nix
    ../../home/git.nix
    ../../home/lsd.nix
    ../../home/tmux.nix
    ../../home/direnv.nix

    ../../home/nixvim
  ];
  flags = {
    purpose = "work";
    editor = "nvim";
    darkMode = false;
  };
  home.packages = with pkgs; [
    dust
    fswatch

    rectangle

    # To use PC mouse with natural scrolling
    nixpkgs-master.mos
    stats
  ];

  home.username = "ivan";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
