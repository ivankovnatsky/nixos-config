{ pkgs, ... }:

{
  programs.nixvim = {
    extraPlugins = [
      pkgs.vimPlugins.himalaya-vim
    ];
  };
}
