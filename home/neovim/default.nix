{ pkgs, ... }:

{
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
      nvim-colorizer-lua
      symbols-outline-nvim
      nvim-lspconfig
      rust-tools-nvim

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

    extraConfig = builtins.readFile ./init.vim;
    extraLuaConfig = builtins.readFile ./init.lua;
  };
}
