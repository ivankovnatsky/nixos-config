syntax on

colorscheme default
set background=dark
set nocompatible
set termguicolors

" edition to default colors scheme
hi TabLine     term=bold,reverse cterm=bold    ctermfg=black ctermbg=white gui=bold guifg=black guibg=white
hi TabLineFill term=bold,reverse cterm=bold    ctermfg=black ctermbg=white gui=bold guifg=black guibg=white
hi TabLineSel  term=reverse      ctermfg=white ctermbg=black guifg=white   guibg=black
hi CursorLine  cterm=bold        ctermbg=white ctermfg=black guibg=white   guifg=black
hi Folded      ctermbg=white

hi Comment gui=italic cterm=italic ctermfg=gray guifg=gray

hi Pmenu ctermbg=black guibg=black
hi PmenuSel ctermfg=black guifg=black

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

set history=10000

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
