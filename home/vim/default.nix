{ config, pkgs, ... }:
{
  home.file.".cache/vim/undo/.keep".text = "";
  programs.vim = {
    enable = true;
    packageConfigurable = pkgs.vim-darwin;
    defaultEditor = if config.variables.editor == "vim" then true else false;
    plugins = with pkgs.vimPlugins; [
      # nerdtree
      # nerdtree-git-plugin
      # vim-nerdtree-syntax-highlight
      # vim-nerdtree-tabs
      ale
      ansible-vim
      async-vim
      asyncomplete-lsp-vim
      asyncomplete-vim
      copilot-vim
      dhall-vim
      fzf-vim
      git-messenger-vim
      neoformat
      rust-vim
      ultisnips
      vim-airline
      vim-airline-themes
      vim-better-whitespace
      vim-commentary
      vim-devicons
      vim-fugitive
      vim-git
      vim-gitgutter
      vim-go
      vim-helm
      vim-jsonnet
      vim-lastplace
      vim-lsp
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
      webapi-vim
    ];
    settings = {
      background = "light";
    };
    extraConfig =
      builtins.readFile (../../home/vim/vimrc) +
      builtins.readFile (../../home/vim/common-plugins.vim) +
      ''
        " I want to run :Lex when I'm not opening a file with vim
        " Also I want Lex to be resized to 20
        autocmd VimEnter * if argc() == 0 | Lex 20 | endif

        " Hide netrw banner
        let g:netrw_banner = 0

        " Set cursor shape depending on mode
        " https://vim.fandom.com/wiki/Change_cursor_shape_in_different_modes#For_tmux_running_in_iTerm2_on_OS_X
        let &t_SI.="\e[6 q" "SI = INSERT mode
        let &t_SR.="\e[4 q" "SR = REPLACE mode
        let &t_EI.="\e[2 q" "EI = NORMAL mode (ELSE)

        " Cursor settings:
        " 1 -> blinking block
        " 2 -> solid block
        " 3 -> blinking underscore
        " 4 -> solid underscore
        " 5 -> blinking vertical bar
        " 6 -> solid vertical bar

        " https://stackoverflow.com/a/58042714
        " Rest option are configured by vim-sensible
        set ttyfast
      '';
  };
}
