{ pkgs, ... }:

{
  imports = [
    # ../../../home/bash.nix
    ../../../home/claude.nix
    ../../../home/gemini.nix
    ../../../home/codex.nix
    ../../../home/gamescope-session.nix
    ../../../home/ghostty.nix
    ../../../home/kitty
    ../../../home/git
    ../../../home/go.nix
    ../../../home/home-session-vars.nix
    ../../../home/lsd.nix
    ../../../home/mpv.nix
    ../../../home/nixvim
    ../../../home/nixvim/plugins/copilot-lua
    ../../../home/npm.nix
    ../../../home/rebuild-diff.nix
    ../../../home/shell.nix
    ../../../home/starship
    ../../../home/tmux.nix
    ../../../home/tweety.nix
    ../../../modules/flags
    ../../../modules/home/manual-packages
    ../../../modules/secrets
    ./btop.nix
    ../../../home/chromium.nix
    ./firefox.nix
    ./flags.nix
    ./gpg.nix
    ./manual-packages.nix
    ./packages.nix
    ./syncthing.nix

    # Desktop environment home configs
    ./desktop.nix
  ];
}
