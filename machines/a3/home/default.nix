{ pkgs, ... }:

{
  imports = [
    # ../../../home/bash.nix
    ../../../home/claude.nix
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
    ../../../home/rebuild-diff.nix
    ../../../home/scripts.nix
    ../../../home/shell.nix
    ../../../home/starship
    ../../../home/tmux.nix
    ../../../home/tweety.nix
    ../../../modules/flags
    ../../../modules/secrets
    ./activation.nix
    ./btop.nix
    ../../../home/chromium.nix
    ./firefox.nix
    ./flags.nix
    ./gpg.nix
    ./packages.nix
    ./syncthing.nix

    # Desktop environment home configs
    ./desktop.nix
  ];
}
