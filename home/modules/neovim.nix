{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      ale
      fzf-vim
      nerdtree
      vim-airline
      vim-commentary
      vim-devicons
      vim-fugitive
      vim-gist
      vim-gitgutter
      vim-markdown
      vim-nix
      vim-repeat
      vim-sensible
      vim-sneak
      vim-lastplace
      lens-vim
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
