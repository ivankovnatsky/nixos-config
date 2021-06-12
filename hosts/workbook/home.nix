{ pkgs, ... }:

{
  imports = [
    ../../home/alacritty.nix
    ../../home/bat.nix
    ../../home/dotfiles.nix
    ../../home/git.nix
    ../../home/hammerspoon
    ../../home/mpv.nix
    ../../home/neovim
    ../../home/task.nix
    ../../home/tmux.nix
    ../../home/zsh.nix
  ];
}
