{ pkgs, ... }:

{
  imports = [
    ../../../home/chromium.nix
    ../../../home/claude.nix
    ../../../home/codex.nix
    ../../../home/gemini.nix
    ../../../home/ghostty.nix
    ../../../home/git
    ../../../home/go.nix
    ../../../home/home-session-vars.nix
    ../../../home/kitty
    ../../../home/lsd.nix
    ../../../home/mpv.nix
    ../../../home/nixvim
    ../../../home/nixvim/plugins/copilot-lua
    ../../../home/npm.nix
    ../../../home/rebuild-diff.nix
    ../../../home/scripts.nix
    ../../../home/shell.nix
    ../../../home/starship
    ../../../home/tmux.nix
    ../../../modules/flags
    ../../../modules/home/manual-packages
    ../../../modules/secrets
    ./btop.nix
    ./firefox.nix
    ./flags.nix
    ./gpg.nix
    ./kwinoutput
    ./manual-packages.nix
    ./packages.nix
    ./plasma.nix
    ./syncthing.nix
  ];
}
