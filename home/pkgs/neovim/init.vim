" vim-nix
" autoformat with nixfmt
autocmd BufWritePost *.nix silent !nixfmt <afile>
autocmd BufWritePost *.nix silent edit

" 'scrooloose/nerdtree'
" open up NERDTree to the right
augroup ProjectDrawer
  autocmd!
  autocmd VimEnter * if argc() == 0 | NERDTree | endif
augroup END

" Show dot files
let NERDTreeShowHidden=1
let NERDTreeShowLineNumbers=1
let NERDTreeMinimalUI=1

" 'vim-airline/vim-airline'
" Enable branch name in vim-airline
" let g:airline#extensions#branch#enabled=1
" let g:airline_powerline_fonts = 1

" 'plasticboy/vim-markdown'
" disable folding
let g:vim_markdown_folding_disabled = 1

" 'ryanoasis/vim-devicons'
" vim-devicons
" after a re-source, fix syntax matching issues (concealing brackets):
if exists('g:loaded_webdevicons')
    call webdevicons#refresh()
endif

" 'camspiers/lens.vim'
let g:lens#disabled_filetypes = ['nerdtree', 'fzf']

" 'w0rp/ale'
" Check Python files with pylint.
let b:ale_linters = ['pylint', 'mdl']

" 'juliosueiras/vim-terraform-completion', { 'for': 'terraform' }
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

if exists("g:loaded_webdevicons")
    call webdevicons#refresh()
endif

colorscheme default
set background=dark
set nocompatible

" edition to default colors scheme
hi TabLine     term=bold,reverse cterm=bold    ctermfg=black ctermbg=white gui=bold guifg=black guibg=white
hi TabLineFill term=bold,reverse cterm=bold    ctermfg=black ctermbg=white gui=bold guifg=black guibg=white
hi TabLineSel  term=reverse      ctermfg=white ctermbg=black guifg=white   guibg=black
hi CursorLine  cterm=bold        ctermbg=white ctermfg=black guibg=white   guifg=black
hi Folded      ctermbg=white

hi Comment gui=italic cterm=italic

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

" remap window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" history complete by word
cmap <C-P> <Up>
cmap <C-N> <Down>

" disable Ex mode
map Q <nop>
