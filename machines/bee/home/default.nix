{ pkgs, ... }:

{
  imports = [
    ../../../home/bash.nix
    ../../../home/git.nix
    ../../../home/gpg.nix
    ../../../home/home-session-vars.nix
    ../../../home/lsd.nix
    ../../../home/nixvim
    ../../../home/rebuild-diff.nix
    ../../../home/scripts.nix
    ../../../home/shell.nix
    ../../../home/starship
    ../../../home/tmux.nix
    ../../../home/tmuxinator.nix
    ../../../modules/flags
    ../../../modules/secrets
    ./activation.nix
    ./flags.nix
    ./vim.nix
    ./env.nix
  ];
}
