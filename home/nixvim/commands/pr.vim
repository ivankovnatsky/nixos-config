function! PrFunction(action)
  if a:action == 'create'
    execute 'terminal ' . g:pr_script . ' create'
  elseif a:action == 'merge'
    execute 'terminal ' . g:pr_script . ' merge'
  elseif a:action == 'view'
    execute '!' . g:pr_script . ' view'
  else
    echoerr "Invalid action: " . a:action
  endif
endfunction
