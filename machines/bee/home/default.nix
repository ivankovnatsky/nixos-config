{ pkgs, ... }:

{
  imports = [
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
    ../../../modules/flags
    ../../../modules/secrets
    ./flags.nix
    ./vim.nix
  ];
}
