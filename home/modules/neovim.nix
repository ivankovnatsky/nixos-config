{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      ale
      fzf-vim
      lens-vim
      nerdtree
      vim-airline
      vim-commentary
      vim-devicons
      vim-fugitive
      vim-gist
      vim-git
      vim-gitgutter
      vim-lastplace
      vim-markdown
      vim-nix
      vim-repeat
      vim-sensible
      vim-sneak
      vim-surround
      vim-terraform
      vim-terraform-completion
      vim-tmux
      vim-visualstar
      webapi-vim
    ];

    extraConfig = builtins.readFile files/init.vim;
  };
}
