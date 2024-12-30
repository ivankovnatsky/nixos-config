{ pkgs, ... }:

{
  imports = [
    ../../home/git.nix
    ../../home/mpv.nix
    ../../home/shell.nix
    ../../home/starship
    ../../home/syncthing.nix
    ../../modules/flags
  ];
  flags = {
    enableFishShell = true;
    purpose = "home";
    editor = "vim";
    darkMode = false;
  };
  home = {
    packages = with pkgs; [
      dust
      fswatch

      watchman
      watchman-make

      rectangle

      # To use PC mouse with natural scrolling
      mos
      stats
      battery-toolkit
      coconutbattery

      magic-wormhole
    ];

    username = "ivan";
    stateVersion = "23.11";
  };
  programs.home-manager.enable = true;
}
