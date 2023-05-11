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
    rnix-lsp
    shellcheck
    shfmt
    terraform-ls
    tflint
    sumneko-lua-language-server
    stylua
    rust-analyzer
    nixpkgs.typst-lsp
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
      nvim-tree-lua
      nvim-web-devicons

      # Vim
      ale
      ansible-vim
      context-vim
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
      vim-tmux
      webapi-vim
      ultisnips
    ];

    extraConfig = builtins.readFile ./init.vim;
    extraLuaConfig = builtins.readFile ./init.lua;
  };
}
