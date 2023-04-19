{ pkgs, ... }:

{
  home.packages = with pkgs; [
    yubikey-manager
  ];

  programs.vim-vint.enable = true;
}
