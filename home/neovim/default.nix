{ config, pkgs, ... }:

let
  nvim-spell-uk-utf8-dictionary = builtins.fetchurl {
    url = "http://ftp.vim.org/vim/runtime/spell/uk.utf-8.spl";
    sha256 = "05180znfdjwqhl2gfsq42jzwqadd7cgr59p9cvz6hw2dlnj6qs71";
  };
in
{
  home.file."${config.xdg.configHome}/nvim/spell/uk.utf-8.spl".source = nvim-spell-uk-utf8-dictionary;

  home.packages = with pkgs; [
    delta
    dhall-lsp-server
    gopls
    mdl
    nodejs
    nodePackages.bash-language-server
    nodePackages.pyright
    nodePackages.js-beautify
    python310Packages.grip
    ripgrep
    nil
    shellcheck
    shfmt
    terraform-ls
    tflint
    sumneko-lua-language-server
    stylua
    typst-lsp
    rufo
    deno
    yarn
    yapf
    taplo
  ];

  home.file.".cache/nvim/undo/.keep".text = "";

  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      # Cmp
      cmp_luasnip
      luasnip
      cmp-buffer
      cmp-cmdline
      cmp-git
      cmp-path
      cmp-nvim-lsp
      nvim-cmp

      # Neovim
      copilot-vim
      git-blame-nvim
      lspkind-nvim
      lualine-nvim
      fidget-nvim
      mkdir-nvim
      symbols-outline-nvim
      nvim-lspconfig
      rust-tools-nvim
      indent-blankline-nvim

      neo-tree-nvim
      nui-nvim
      plenary-nvim

      todo-comments-nvim
      nvim-web-devicons

      inc-rename-nvim
      dressing-nvim

      octo-nvim
      telescope-nvim

      # Vim
      # TODO: Move to https://github.com/mfussenegger/nvim-lint
      ale
      ansible-vim
      asyncrun-vim
      dhall-vim
      fzf-vim
      neoformat
      rust-vim
      vim-better-whitespace
      vim-commentary
      vim-fugitive
      vim-git
      vim-gitgutter
      vim-go
      vim-helm
      vim-jsonnet
      vim-lastplace
      vim-markdown
      vim-nix
      vim-repeat
      vim-rhubarb
      vim-sensible
      vim-sleuth
      vim-sneak
      vim-strip-trailing-whitespace
      vim-surround
      vim-terraform
      vim-terraform-completion
      vim-speeddating
      vim-eunuch
      vim-tmux
      webapi-vim
      ultisnips
    ];

    # I want to split general config that my non work machine would also agree
    # and development, which will be under neovim/ directory for now.
    extraConfig =
      builtins.readFile (../vim/vimrc) +
      "\n" +
      builtins.readFile (./vim/common-plugins.vim) +
      "\n" +
      builtins.readFile (./init.vim)
    ;

    extraLuaConfig =
      ''
        vim.opt.background = "dark"
      '' +
      builtins.readFile ./init.lua;
  };
}
