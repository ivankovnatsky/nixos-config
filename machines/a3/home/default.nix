{ pkgs, ... }:

{
  imports = [
    # ../../../home/bash.nix
    # ../../../home/nixvim/plugins/copilot-lua
    # ./mangohud.nix
    ../../../home/ccstatusline.nix
    ../../../home/chromium.nix
    ../../../home/claude.nix
    ../../../home/codex.nix
    ../../../home/gamescope-session.nix
    ../../../home/gemini.nix
    ../../../home/ghostty.nix
    ../../../home/git
    ../../../home/go.nix
    ../../../home/home-session-vars.nix
    ../../../home/kitty
    ../../../home/lsd.nix
    ../../../home/mpv.nix
    ../../../home/nixvim
    ../../../home/npm.nix
    ../../../home/rebuild-diff.nix
    ../../../home/scripts.nix
    ../../../home/shell.nix
    ../../../home/sops.nix
    ../../../home/starship
    ../../../home/tmux.nix
    ../../../home/tweety.nix
    ../../../modules/flags
    ../../../modules/home/manual-packages
    ./btop.nix
    ./desktop.nix # Desktop environment home configs
    ./firefox.nix
    ./flags.nix
    ./games.nix
    ./gpg.nix
    ./manual-packages.nix
    ./packages.nix
    ./syncthing.nix
  ];
}
