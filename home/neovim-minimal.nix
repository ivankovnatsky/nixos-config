{ config, pkgs, lib, ... }:

{
  programs.neovim = {
    enable = true;

    extraConfig = ''
      set mouse=
      set termguicolors
    '';
  };
}
