{ config, pkgs, ... }:

{
  imports = [
    ../../home/git.nix
    ../../home/mpv.nix
    # ../../home/aichat.nix

    ../../modules/flags
    # ../../modules/secrets
  ];
  flags = {
    purpose = "home";
    editor = "vim";
    darkMode = false;
  };
  home.packages = with pkgs; [
    dust
    fswatch

    watchman
    watchman-make

    ollama
    rectangle

    # To use PC mouse with natural scrolling
    nixpkgs-master.mos
    stats
  ];

  home.username = "ivan";
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
