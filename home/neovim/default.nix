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
  ];

  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      ale
      ansible-vim
      cmp-buffer
      cmp-cmdline
      cmp-nvim-lsp
      cmp-path
      cmp_luasnip
      context-vim
      copilot-vim
      dhall-vim
      fidget-nvim
      fzf-vim
      git-blame-nvim
      lspkind-nvim
      lualine-nvim
      luasnip
      mkdir-nvim
      neoformat
      nvim-cmp
      nvim-colorizer-lua
      symbols-outline-nvim
      nvim-lspconfig
      nvim-tree-lua
      nvim-web-devicons
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
    ];

    extraConfig = builtins.readFile ./init.vim;
    extraLuaConfig = builtins.readFile ./init.lua;
  };
}
