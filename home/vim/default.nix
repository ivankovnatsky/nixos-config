{ pkgs, ... }:
{
  home.file.".cache/vim/undo/.keep".text = "";
  programs.vim = {
    enable = true;
    packageConfigurable = pkgs.vim;
    plugins = with pkgs.vimPlugins; [
      async-vim
      vim-lsp
      asyncomplete-lsp-vim
      asyncomplete-vim
      vim-devicons
      vim-nerdtree-tabs
      vim-nerdtree-syntax-highlight
      nerdtree-git-plugin
      ale
      ansible-vim
      dhall-vim
      fzf-vim
      git-messenger-vim
      neoformat
      nerdtree
      rust-vim
      vim-airline
      vim-airline-themes
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
      vim-vinegar
      vim-vsnip
      vim-vsnip-integ
      vim-which-key
      ultisnips
      webapi-vim
    ];
    extraConfig = builtins.readFile ../neovim/init.vim;
  };
}
