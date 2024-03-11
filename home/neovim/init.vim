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
