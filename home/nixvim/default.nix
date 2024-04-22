{ config, pkgs, ... }:

let
  nvim-spell-uk-utf8-dictionary = builtins.fetchurl {
    url = "http://ftp.vim.org/vim/runtime/spell/uk.utf-8.spl";
    sha256 = "05180znfdjwqhl2gfsq42jzwqadd7cgr59p9cvz6hw2dlnj6qs71";
  };
in
{
  home.file."${config.xdg.configHome}/nvim/spell/uk.utf-8.spl".source = nvim-spell-uk-utf8-dictionary;
  imports = [
    ./config
    ./options
    ./keymaps
    ./plugins
  ];
  programs.nixvim = {
    enable = true;
    globals.mapleader = "<Space>";
    extraPlugins = with pkgs.vimPlugins; [
      vim-nix
      vim-strip-trailing-whitespace
      vim-sensible
      vim-sleuth
      neoformat
    ];
  };
}
