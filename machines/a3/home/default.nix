{ pkgs, ... }:

{
  imports = [
    ../../../home/claude.nix
    ../../../home/gamescope-session.nix
    ../../../home/ghostty.nix
    ../../../home/kitty
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
    ../../../home/tmuxinator.nix
    ../../../home/tweety.nix
    ../../../modules/flags
    ../../../modules/secrets
    ./activation.nix
    ../../../home/chromium.nix
    ./firefox.nix
    ./flags.nix
    ./gnome.nix
    ./gpg.nix
    ./kwinoutput
    ./packages.nix
    ./plasma.nix
    ./syncthing.nix
    ./tmuxinator.nix
  ];
}
