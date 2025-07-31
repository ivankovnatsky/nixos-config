{ pkgs, ... }:

{
  imports = [
    ../../../home/claude.nix
    ../../../home/gamescope-session.nix
    ../../../home/ghostty.nix
    ../../../home/git.nix
    ../../../home/go.nix
    ../../../home/home-session-vars.nix
    ../../../home/lsd.nix
    ../../../home/nixvim
    ../../../home/nixvim/plugins/copilot-lua
    ../../../home/rebuild-diff.nix
    ../../../home/scripts.nix
    ../../../home/shell.nix
    ../../../home/starship
    ../../../home/tmux.nix
    ../../../home/tweety.nix
    ../../../modules/flags
    ../../../modules/secrets
    ./firefox.nix
    ./flags.nix
    ./gnome.nix
    ./gpg.nix
    ./kde.nix
    ./packages.nix
    ./plasma.nix
    ./syncthing.nix
  ];
}
