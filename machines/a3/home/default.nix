{ pkgs, ... }:

{
  imports = [
    # ../../../home/bash.nix
    ../../../home/btop.nix
    ../../../home/claude.nix
    ../../../home/gamescope-session.nix
    ../../../home/ghostty.nix
    ../../../home/kitty
    ../../../home/git.nix
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
    ../../../home/tmuxinator.nix
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

    # Desktop environment home configs (disable for dwm)
    # ./gnome.nix       # GNOME config

    # KDE/Plasma configs
    ./kwinoutput # KDE window output config
    ./plasma.nix # KDE Plasma config
  ];
}
