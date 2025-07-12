{ pkgs, ... }:

{
  imports = [
    ../../../home/git.nix
    ../../../home/lsd.nix
    ../../../home/nixvim
    ../../../home/rebuild-diff.nix
    ../../../home/scripts.nix
    ../../../home/shell.nix
    ../../../home/starship
    ../../../home/tmux.nix
    ../../../modules/flags
    ./gnome.nix
    ./kde.nix
    ./flags.nix
    ./home-session-vars.nix
    ./firefox.nix
    ./packages.nix
    ./syncthing.nix
  ];
}
