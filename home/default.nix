{ config, super, ... }:

{
  imports = [
    ./neovim
    ./alacritty.nix
    ./bat.nix
    ./dotfiles.nix
    ./firefox.nix
    ./nightshift.nix
    ./git.nix
    ./gh.nix
    ./go.nix
    ./gpg.nix
    ./gtk.nix
    ./i3status.nix
    ./mpv.nix
    ./password-store.nix
    ./ranger.nix
    ./task.nix
    ./tmux.nix
    ./zsh.nix

    ../modules/default.nix
    ../modules/secrets.nix
  ];

  device = super.device;
  variables = super.variables;
  secrets = super.secrets;
}
