syntax on
set encoding=utf-8
scriptencoding=utf-8

" https://www.reddit.com/r/neovim/comments/olrtof/a_fix_for_neovim_been_slow_for_fish_users/
set shell=/bin/sh

colorscheme default
set background=dark
set termguicolors

let mapleader='<Space>'
set mouse=

" Edition to default colors scheme
hi TabLine ctermfg=black guifg=black
hi Folded  ctermbg=white
hi Visual  cterm=bold ctermbg=white ctermfg=black guibg=white guifg=black
hi Comment gui=italic cterm=italic ctermfg=gray guifg=gray

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

" Search down into subfolders
" tab-completion for all file-related tasks
set path+=**

" Display all matching files when we tab complete
set wildmenu

" Display commands typing in
set showcmd

set tabpagemax=100
set showtabline=2

set autoindent
set smartindent
filetype indent plugin on

set list

" Undo file even after vim exists
if has('persistent_undo')
  set undofile
  if has('nvim')
    set undodir=~/.cache/nvim/undo/
  elseif has('vim_starting')
    set undodir=~/.cache/vim/undo/
  endif
endif

" Indent by filetype
augroup indent
  autocmd FileType tex,yaml,conf,vim,template,markdown,javascript setlocal ts=2 sts=2 sw=2 expandtab
  autocmd FileType cpp,c setlocal ts=8 sts=8 sw=8 noexpandtab
  autocmd BufEnter,BufNew *.hcl setlocal ts=2 sts=2 sw=2 expandtab
  autocmd BufRead,BufNewFile *.hcl set filetype=terraform
  autocmd FileType go setlocal noexpandtab tabstop=8 shiftwidth=8
augroup end

" Fix working crontab for neovim
augroup crontab
  autocmd filetype crontab setlocal nobackup nowritebackup
augroup END

" Remap window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" History complete by word
cmap <C-P> <Up>
cmap <C-N> <Down>

" Disable Ex mode
map Q <nop>

" Set Ukrainian key mappings: this will let me navigate in vim even if did
" not moved back to english keyboard layout
set langmap=йq,цw,уe,кr,еt,нy,гu,шi,щo,зp,х[,ї],фa,іs,вd,аf,пg,рh,оj,лk,дl,ж\\;,
  \є',ґ\\,яz,чx,сc,мv,иb,тn,ьm,б\\,,ю.,,ЙQ,ЦW,УE,КR,ЕT,НY,НY,ГU,ШI,ЩO,ЗP,Х{,Ї},ФA,
  \ІS,ВD,АF,ПG,РH,ОJ,ЛK,ДL,Ж\\:,Є\\",Ґ\|,ЯZ,ЧX,СC,МV,ИB,ТN,ЬM,Б\\<,Ю>,№#

" {{{ visual-star-search
" https://www.reddit.com/r/neovim/comments/keutw5/comment/gh9w1mf/?utm_source=share&utm_medium=web3x
function! s:VSetSearch()
  let temp = @@
  norm! gvy
  let @/ = '\V' . substitute(escape(@@, '\'), '\n', '\\n', 'g')
  call histadd('/', substitute(@/, '[?/]', '\="\\%d".char2nr(submatch(0))', 'g'))
  let @@ = temp
endfunction

vnoremap * :<C-u>call <SID>VSetSearch()<CR>/<CR>
vnoremap # :<C-u>call <SID>VSetSearch()<CR>?<CR>
" }}}

" Plugins
" {{{ dhall-vim
augroup dhall
  autocmd FileType dhall setlocal ts=2 sts=2 sw=2 expandtab
augroup END
" }}}
" {{{ vim-jsonnet
augroup jsonnet
  autocmd FileType jsonnet setlocal ts=2 sts=2 sw=2 expandtab
augroup END
" }}}
" {{{ vim-commentary
augroup commentary
  autocmd FileType helm setlocal commentstring=#\ %s
augroup END
" }}}
" {{{ neoformat
augroup fmt
  autocmd!
  autocmd BufWritePre * undojoin | Neoformat
augroup END
" }}}
" {{{ vim-helm
augroup helm
  autocmd FileType helm setlocal ts=2 sts=2 sw=2 expandtab
augroup END
" }}}
" {{{ rust-vim
let g:rustfmt_autosave = 1
" }}}
" {{{ vim-sneak
let g:sneak#label = 1
" }}}
" {{{ fzf-vim
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   "rg --column --hidden --no-ignore-parent --glob '!.git/*' --line-number --no-heading --color=always --smart-case --with-filename "
  \   .<q-args>, 1, fzf#vim#with_preview(), <bang>0)

command! -bang -nargs=* GGrep
  \ call fzf#vim#grep(
  \   'git grep --line-number -- '.fzf#shellescape(<q-args>),
  \   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)
" }}}
" {{{ ale
let b:ale_linters = ['pylint', 'mdl']
" }}}
" {{{ vim-markdown
let g:vim_markdown_folding_disabled = 1
" }}}
" {{{ vim-terraform-completion
set completeopt-=preview

" (Optional)Hide Info(Preview) window after completions
augroup terraform_completion
  autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
  autocmd InsertLeave * if pumvisible() == 0|pclose|endif
augroup END

" (Optional) Default: 0, enable(1)/disable(0) plugin's keymapping
let g:terraform_completion_keys = 1

" (Optional) Default: 1, enable(1)/disable(0) terraform module registry completion
let g:terraform_registry_module_completion = 0
" }}}

" This block sets config only for vim
if has('vim_starting')
  if executable('terraform-ls')
    augroup lsp
      au User lsp_setup call lsp#register_server({
          \ 'name': 'terraform-ls',
          \ 'cmd': {server_info->['terraform-ls', 'serve']},
          \ 'whitelist': ['terraform'],
          \ })
    augroup END
  endif

  function! s:on_lsp_buffer_enabled() abort
      setlocal omnifunc=lsp#complete
      setlocal signcolumn=yes
      if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
      nmap <buffer> gd <plug>(lsp-definition)
      nmap <buffer> gs <plug>(lsp-document-symbol-search)
      nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
      nmap <buffer> gr <plug>(lsp-references)
      nmap <buffer> gi <plug>(lsp-implementation)
      nmap <buffer> gt <plug>(lsp-type-definition)
      nmap <buffer> <leader>rn <plug>(lsp-rename)
      nmap <buffer> [g <plug>(lsp-previous-diagnostic)
      nmap <buffer> ]g <plug>(lsp-next-diagnostic)
      nmap <buffer> K <plug>(lsp-hover)
      nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
      nnoremap <buffer> <expr><c-d> lsp#scroll(-4)

      let g:lsp_format_sync_timeout = 1000
      augroup lsp_format
        autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')
      augroup END

      " refer to doc to add more commands
  endfunction

  augroup lsp_install
      au!
      " call s:on_lsp_buffer_enabled only for languages that has the server registered.
      autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
  augroup END
endif

" Change filetype for files with *.typ extension
augroup typst
  autocmd BufNewFile,BufRead *.typ set filetype=typst
augroup END
