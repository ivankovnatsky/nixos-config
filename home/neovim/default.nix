{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      fzf-vim
      vim-commentary
      vim-fugitive
      vim-gist
      vim-git
      vim-gitgutter
      vim-lastplace
      vim-repeat
      vim-sensible
      nerdtree-git-plugin
      nvim-toggleterm-lua

      {
        plugin = vim-sneak;
        config = ''
          let g:sneak#label = 1
          map f <Plug>Sneak_f
          map F <Plug>Sneak_F
          map t <Plug>Sneak_t
          map T <Plug>Sneak_T
        '';
      }

      vim-surround
      vim-tmux
      vim-visualstar
      webapi-vim

      {
        plugin = ale;
        config = ''
          let b:ale_linters = ['pylint', 'mdl']
        '';
      }

      {
        plugin = lens-vim;
        config = ''
          let g:lens#disabled_filetypes = ['nerdtree', 'fzf']
        '';
      }

      {
        plugin = nerdtree;
        config = ''
          augroup ProjectDrawer
            autocmd!
            autocmd VimEnter * if argc() == 0 | NERDTree | endif
          augroup END

          let NERDTreeShowHidden=1
          let NERDTreeShowLineNumbers=1
          let NERDTreeMinimalUI=1
          let NERDTreeWinSize=40
        '';
      }

      {
        plugin = vim-airline;
        config = ''
          let g:airline#extensions#branch#enabled=1
          let g:airline_powerline_fonts = 1
          let g:airline_left_sep=' '
          let g:airline_right_sep=' '
        '';
      }

      {
        plugin = vim-devicons;

        config = ''
          if exists('g:loaded_webdevicons')
              call webdevicons#refresh()
          endif
        '';
      }

      {
        plugin = vim-markdown;
        config = ''
          let g:vim_markdown_folding_disabled = 1
        '';
      }

      {
        plugin = vim-nix;
        config = ''
          autocmd BufWritePost *.nix silent !nixpkgs-fmt <afile>
          autocmd BufWritePost *.nix silent edit
        '';
      }

      {
        plugin = vim-terraform;
        config = ''
          let g:terraform_fmt_on_save=1
        '';
      }

      {
        plugin = vim-terraform-completion;
        config = ''
          set completeopt-=preview

          " (Optional)Hide Info(Preview) window after completions
          autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
          autocmd InsertLeave * if pumvisible() == 0|pclose|endif

          " (Optional) Default: 0, enable(1)/disable(0) plugin's keymapping
          let g:terraform_completion_keys = 1

          " (Optional) Default: 1, enable(1)/disable(0) terraform module registry completion
          let g:terraform_registry_module_completion = 0
        '';
      }
    ];

    extraConfig = builtins.readFile ./init.vim;
  };
}
