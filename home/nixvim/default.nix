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
    ./opts
    ./keymaps
    ./plugins

    ./plugins/lsp
    ./plugins/none-ls
    ./plugins/lspsaga
    # ./plugins/gitsigns
    ./plugins/git-blame
  ];
  # https://github.com/elythh/nixvim
  programs.nixvim = {
    enable = true;
    globals.mapleader = " ";
    extraPlugins = with pkgs.vimPlugins; [
      vim-nix
      vim-strip-trailing-whitespace
      vim-sensible
      vim-sleuth
      vim-sneak
      vim-eunuch

      tokyonight-nvim
      # material-nvim
      # onenord-nvim
    ];
    # extraConfigLua =
    #   if config.flags.darkMode then
    #     ''
    #       vim.opt.background = "dark"
    #       -- vim.cmd('colorscheme material')
    #       -- vim.g.material_style = "darker"

    #       vim.cmd('colorscheme onenord')
    #     ''
    #   else
    #     ''
    #       vim.opt.background = "light"
    #       -- vim.cmd('colorscheme material')
    #       -- vim.g.material_style = "lighter"

    #       vim.cmd('colorscheme onenord-light')
    #     '';
  };
}
