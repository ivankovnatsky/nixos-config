{ pkgs, ... }: {
  environment.systemPackages = with pkgs;
    [
      (neovim.override {
        configure = {
          packages.myPlugins = with pkgs.vimPlugins; {
            start = [
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
              vim-surround
              vim-terraform
              vim-terraform-completion
              vim-tmux
              vim-visualstar
              webapi-vim
            ];
            opt = [ ];
          };
          customRC = ''
            syntax on
            colorscheme default
            set background=dark
            set nocompatible

            " edition to default colors scheme
            hi TabLine     term=bold,reverse cterm=bold    ctermfg=black ctermbg=white gui=bold guifg=black guibg=white
            hi TabLineFill term=bold,reverse cterm=bold    ctermfg=black ctermbg=white gui=bold guifg=black guibg=white
            hi TabLineSel  term=reverse      ctermfg=white ctermbg=black guifg=white   guibg=black
            hi CursorLine  cterm=bold        ctermbg=white ctermfg=black guibg=white   guifg=black
            hi Folded      ctermbg=white

            set expandtab
            set tabstop=4
            set shiftwidth=4

            set nobackup
            set noswapfile

            set number relativenumber
            set wrap
            set cursorline
            set foldmethod=marker

            set autoread
            set autowrite
            set lazyredraw

            set showmatch
            set hlsearch
            set smartcase
            set ignorecase

            set history=1000

            set iskeyword=@,48-57,_,192-255

            " search down into subfolders
            " tab-completion for all file-related tasks
            set path+=**

            " display all matching files when we tab complete
            set wildmenu

            " display commands typing in
            set showcmd

            set tabpagemax=100

            set autoindent
            set smartindent
            filetype indent plugin on

            set list
            set encoding=utf-8

            " undo file even after neovim exists
            if has('persistent_undo')
            set undofile
            set undodir=~/.cache/neovim/undo/
            endif

            " indent by filetype
            autocmd FileType tex,yaml,conf,vim,markdown setlocal ts=2 sts=2 sw=2 expandtab
            autocmd FileType cpp,c setlocal ts=8 sts=8 sw=8 noexpandtab

            autocmd BufEnter,BufNew *.hcl setlocal ts=2 sts=2 sw=2 expandtab

            " terragrunt
            autocmd BufRead,BufNewFile *.hcl set filetype=terraform

            " go
            autocmd FileType go setlocal noexpandtab tabstop=8 shiftwidth=8

            " Fixed working crontab for neovim
            autocmd filetype crontab setlocal nobackup nowritebackup

            " remap
            nnoremap <C-h> <C-w>h
            nnoremap <C-j> <C-w>j
            nnoremap <C-k> <C-w>k
            nnoremap <C-l> <C-w>l

            cmap <C-P> <Up>
            cmap <C-N> <Down>

            " only do this part when compiled with support for autocommands.
            if has("autocmd")
              " When editing a file, always jump to the last known cursor position.
              " Don't do it when the position is invalid or when inside an event handler
              " (happens when dropping a file on gvim).
              autocmd BufReadPost *
                \ if line("'\"") > 0 && line("'\"") <= line("$") |
                \   exe "normal g`\"" |
                \ endif
            endif " has("autocmd")

            " options, plugin: hashivim/vim-terraform
            let g:terraform_fmt_on_save=1

            " options, plugin: juliosueiras/vim-terraform-completion
            " (Optional)Remove Info(Preview) window
            set completeopt-=preview

            " (Optional)Hide Info(Preview) window after completions
            autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
            autocmd InsertLeave * if pumvisible() == 0|pclose|endif

            " (Optional) Default: 0, enable(1)/disable(0) plugin's keymapping
            let g:terraform_completion_keys = 1

            " (Optional) Default: 1, enable(1)/disable(0) terraform module registry completion
            let g:terraform_registry_module_completion = 0

            " Check Python files with pylint.
            let b:ale_linters = ['pylint', 'mdl']

            " Enable branch name in vim-airline
            let g:airline#extensions#branch#enabled=1
            let g:airline_powerline_fonts = 1

            " open up NERDTree to the right
            augroup ProjectDrawer
              autocmd!
              autocmd VimEnter * if argc() == 0 | NERDTree | endif
            augroup END

            " Show dot files
            let NERDTreeShowHidden=1
            let NERDTreeMinimalUI=1

            " vim-devicons
            " after a re-source, fix syntax matching issues (concealing brackets):
            if exists('g:loaded_webdevicons')
              call webdevicons#refresh()
            endif

            " vim-markdown
            let g:vim_markdown_folding_disabled = 1
          '';
        };
      })
    ];
}
